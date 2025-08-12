#!/bin/bash

# Shadowsocks Server Provisioning Script for Amazon Linux EC2
# Usage: ./provision_shadowsocks.sh <ec2-ip> <ssh-key-path> <shadowsocks-port> <shadowsocks-password>

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if correct number of arguments provided
if [ $# -ne 4 ]; then
    print_error "Usage: $0 <ec2-ip> <ssh-key-path> <shadowsocks-port> <shadowsocks-password>"
    print_error "Example: $0 54.123.45.67 ~/.ssh/my-key.pem 8388 mySecurePassword123"
    exit 1
fi

# Parse arguments
EC2_IP="$1"
SSH_KEY="$2"
SS_PORT="$3"
SS_PASSWORD="$4"

# Validate inputs
if [ ! -f "$SSH_KEY" ]; then
    print_error "SSH key file not found: $SSH_KEY"
    exit 1
fi

if ! [[ "$SS_PORT" =~ ^[0-9]+$ ]] || [ "$SS_PORT" -lt 1 ] || [ "$SS_PORT" -gt 65535 ]; then
    print_error "Invalid port number: $SS_PORT (must be between 1-65535)"
    exit 1
fi

if [ ${#SS_PASSWORD} -lt 8 ]; then
    print_warning "Password is less than 8 characters. Consider using a stronger password."
fi

print_header "Starting Shadowsocks server provisioning on $EC2_IP"

# SSH connection options
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
SSH_USER="ec2-user"

# Test SSH connectivity
print_status "Testing SSH connectivity to $EC2_IP..."
if ! ssh $SSH_OPTS $SSH_USER@$EC2_IP "echo 'SSH connection successful'" >/dev/null 2>&1; then
    print_error "Cannot establish SSH connection to $EC2_IP"
    print_error "Please verify:"
    print_error "  - EC2 instance is running"
    print_error "  - Security group allows SSH (port 22)"
    print_error "  - SSH key is correct"
    print_error "  - IP address is correct"
    exit 1
fi

print_status "SSH connection successful"

# Create the provisioning script to run on the remote server
REMOTE_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -e

echo "[INFO] Starting Shadowsocks installation..."

# Update system packages
echo "[INFO] Updating system packages..."
sudo yum update -y

# Install required packages
echo "[INFO] Installing required packages..."
sudo yum install -y python3 python3-pip git

# Install shadowsocks via pip (unified approach for all Linux distributions)
echo "[INFO] Installing shadowsocks via Python pip..."
sudo yum install -y python3 python3-pip

# Install libsodium for additional encryption support
echo "[INFO] Installing libsodium for enhanced encryption support..."
sudo yum install -y gcc python3-devel libffi-devel openssl-devel
sudo pip3 install pynacl

# Install shadowsocks Python version
echo "[INFO] Installing shadowsocks Python package..."
sudo pip3 install shadowsocks

# Verify installation
if ! command -v ssserver &> /dev/null; then
    echo "[ERROR] shadowsocks installation failed"
    exit 1
fi

SS_SERVER_BIN="ssserver"

# Create shadowsocks directory
sudo mkdir -p /etc/shadowsocks

# Create shadowsocks configuration file with optimized settings
echo "[INFO] Creating shadowsocks configuration..."
sudo tee /etc/shadowsocks/config.json > /dev/null << EOL
{
    "server": "0.0.0.0",
    "server_port": SS_PORT_PLACEHOLDER,
    "password": "SS_PASSWORD_PLACEHOLDER",
    "timeout": 60,
    "method": "aes-256-cfb",
    "fast_open": true,
    "workers": 4,
    "prefer_ipv6": false,
    "no_delay": true,
    "reuse_port": true
}
EOL

# Create systemd service file
echo "[INFO] Creating systemd service..."
sudo tee /etc/systemd/system/shadowsocks.service > /dev/null << EOL
[Unit]
Description=Shadowsocks Server
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/ssserver -c /etc/shadowsocks/config.json
Restart=on-failure
RestartSec=5
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=shadowsocks

[Install]
WantedBy=multi-user.target
EOL

# Enable and start shadowsocks service
echo "[INFO] Enabling and starting shadowsocks service..."
sudo systemctl daemon-reload
sudo systemctl enable shadowsocks
sudo systemctl start shadowsocks

# Check if service is running
if sudo systemctl is-active --quiet shadowsocks; then
    echo "[SUCCESS] Shadowsocks service is running"
else
    echo "[ERROR] Failed to start shadowsocks service"
    sudo systemctl status shadowsocks
    exit 1
fi

# Configure firewall (if firewalld is running)
if sudo systemctl is-active --quiet firewalld; then
    echo "[INFO] Configuring firewall..."
    sudo firewall-cmd --permanent --add-port=SS_PORT_PLACEHOLDER/tcp
    sudo firewall-cmd --permanent --add-port=SS_PORT_PLACEHOLDER/udp
    sudo firewall-cmd --reload
    echo "[INFO] Firewall configured for port SS_PORT_PLACEHOLDER"
fi

# Optimize system for shadowsocks and fix file descriptor limits
echo "[INFO] Applying system optimizations and fixing file descriptor limits..."

# Set system-wide file descriptor limits
sudo tee -a /etc/security/limits.conf > /dev/null << EOL

# Shadowsocks file descriptor limits
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
nobody soft nofile 65536
nobody hard nofile 65536
EOL

# Set session limits
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session > /dev/null 2>&1 || echo "[INFO] PAM limits already configured or not applicable"

# Update systemd service limits
sudo mkdir -p /etc/systemd/system/shadowsocks.service.d
sudo tee /etc/systemd/system/shadowsocks.service.d/limits.conf > /dev/null << EOL
[Service]
LimitNOFILE=65536
LimitNPROC=65536
EOL

# Apply kernel parameters
sudo tee -a /etc/sysctl.conf > /dev/null << EOL

# Shadowsocks optimizations - File and Network Limits
fs.file-max = 1000000
fs.nr_open = 1000000

# Network optimizations
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 65536
net.core.wmem_default = 65536
net.core.netdev_max_backlog = 4096
net.core.somaxconn = 4096

# TCP optimizations
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 65536 62914560
net.ipv4.tcp_wmem = 4096 65536 62914560
net.ipv4.tcp_mtu_probing = 1
EOL

# Try to set BBR congestion control if available
if [ -f /proc/sys/net/ipv4/tcp_congestion_control ]; then
    echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf > /dev/null
fi

# Apply netfilter optimizations only if ALL required files are available
if [ -f /proc/sys/net/netfilter/nf_conntrack_max ] && \
   [ -f /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established ] && \
   [ -f /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_time_wait ] && \
   [ -f /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_close_wait ] && \
   [ -f /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_fin_wait ]; then
    echo "[INFO] Applying netfilter connection tracking optimizations..."
    sudo tee -a /etc/sysctl.conf > /dev/null << EOL

# Connection tracking (only if all netfilter modules are loaded)
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
EOL
else
    echo "[INFO] Netfilter connection tracking settings not fully available, skipping those optimizations"
fi

sudo sysctl -p 2>/dev/null || echo "[WARNING] Some sysctl settings could not be applied (this is usually harmless)"

# Clean up any problematic netfilter entries that might have been added previously
sudo sed -i '/net.netfilter.nf_conntrack_tcp_timeout/d' /etc/sysctl.conf

# Apply limits immediately for current session
ulimit -n 65536

echo "[SUCCESS] Shadowsocks server installation completed!"
echo "[INFO] System optimizations applied - server restart recommended for full effect"
echo "[INFO] Server is running on port SS_PORT_PLACEHOLDER"
echo "[INFO] File descriptor limit set to 65536 to handle many connections"
echo "[INFO] Server is running on port SS_PORT_PLACEHOLDER"
echo "[INFO] You can check the service status with: sudo systemctl status shadowsocks"
echo "[INFO] View logs with: sudo journalctl -u shadowsocks -f"
EOF
)

# Replace placeholders in the script
REMOTE_SCRIPT=${REMOTE_SCRIPT//SS_PORT_PLACEHOLDER/$SS_PORT}
REMOTE_SCRIPT=${REMOTE_SCRIPT//SS_PASSWORD_PLACEHOLDER/$SS_PASSWORD}

# Copy and execute the script on the remote server
print_header "Installing Shadowsocks server..."
print_status "This may take a few minutes..."

echo "$REMOTE_SCRIPT" | ssh $SSH_OPTS $SSH_USER@$EC2_IP 'bash -s'

# Verify installation
print_header "Verifying installation..."
if ssh $SSH_OPTS $SSH_USER@$EC2_IP "sudo systemctl is-active --quiet shadowsocks"; then
    print_status "✅ Shadowsocks service is running successfully"
else
    print_error "❌ Shadowsocks service is not running"
    print_error "Check logs on the server with: sudo journalctl -u shadowsocks -f"
    exit 1
fi

# Display connection information
print_header "Installation Complete!"
echo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  Shadowsocks Server Configuration${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${BLUE}Server IP:${NC}     $EC2_IP"
echo -e "${BLUE}Port:${NC}          $SS_PORT"
echo -e "${BLUE}Password:${NC}      $SS_PASSWORD"
echo -e "${BLUE}Encryption:${NC}    aes-256-cfb"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
print_status "Client Configuration JSON:"
echo "{
  \"server\": \"$EC2_IP\",
  \"server_port\": $SS_PORT,
  \"password\": \"$SS_PASSWORD\",
  \"method\": \"aes-256-cfb\"
}"
echo
print_status "Server management commands (run on EC2 instance):"
echo "  • Check status:  sudo systemctl status shadowsocks"
echo "  • View logs:     sudo journalctl -u shadowsocks -f"
echo "  • Restart:       sudo systemctl restart shadowsocks"
echo "  • Stop:          sudo systemctl stop shadowsocks"
echo "  • Start:         sudo systemctl start shadowsocks"
echo
print_warning "Important System Notes:"
echo "  • File descriptor limits have been increased to handle many connections"
echo "  • System has been optimized for high-performance networking"
echo "  • BBR congestion control enabled for better performance"
echo "  • Consider rebooting the EC2 instance for all optimizations to take effect"
echo "  • Ensure EC2 security group only allows necessary ports"
echo "  • Consider using a strong, unique password"
echo "  • Monitor server logs regularly"
echo "  • Keep the system updated with 'sudo yum update'"
echo
print_status "🎉 Shadowsocks server is ready to use!"