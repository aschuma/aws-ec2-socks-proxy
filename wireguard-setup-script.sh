#!/bin/bash

# WireGuard VPN Setup Script
# Usage: ./setup-wireguard.sh <EC2_IP> <SSH_KEY_PATH> [CLIENT_NAME]

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check arguments
if [ $# -lt 2 ]; then
    print_error "Usage: $0 <EC2_IP> <SSH_KEY_PATH> [CLIENT_NAME]"
    echo "Example: $0 54.123.45.67 ~/.ssh/my-key.pem laptop"
    exit 1
fi

EC2_IP="$1"
SSH_KEY="$2"
CLIENT_NAME="${3:-client}"
WG_PORT="51820"
VPN_SUBNET="10.8.0"

# Validate inputs
if [ ! -f "$SSH_KEY" ]; then
    print_error "SSH key file not found: $SSH_KEY"
    exit 1
fi

if ! [[ "$EC2_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    print_error "Invalid IP address format: $EC2_IP"
    exit 1
fi

print_status "Starting WireGuard setup for EC2 instance: $EC2_IP"
print_status "Using SSH key: $SSH_KEY"
print_status "Client name: $CLIENT_NAME"

# Test SSH connection
print_status "Testing SSH connection..."
if ! ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" "echo 'SSH connection successful'" > /dev/null 2>&1; then
    print_error "Cannot connect to EC2 instance via SSH"
    print_error "Please check:"
    print_error "  - EC2 instance is running"
    print_error "  - Security group allows SSH (port 22)"
    print_error "  - SSH key is correct"
    print_error "  - IP address is correct"
    exit 1
fi
print_success "SSH connection established"

# Create server setup script
print_status "Creating server setup script..."
cat > /tmp/wg-server-setup.sh << 'EOF'
#!/bin/bash
set -e

echo "[INFO] Starting WireGuard server setup..."

# Detect Amazon Linux version and install WireGuard
echo "[INFO] Installing WireGuard..."
if grep -q "Amazon Linux 2023" /etc/os-release; then
    sudo yum update -y
    sudo yum install -y wireguard-tools
elif grep -q "Amazon Linux 2" /etc/os-release; then
    sudo yum update -y
    sudo amazon-linux-extras install -y epel
    sudo yum install -y wireguard-tools
else
    echo "[ERROR] Unsupported Amazon Linux version"
    exit 1
fi

# Enable IP forwarding
echo "[INFO] Enabling IP forwarding..."
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Create WireGuard directory
sudo mkdir -p /etc/wireguard

# Generate server keys (work from temp directory to avoid permission issues)
echo "[INFO] Generating server keys..."
sudo wg genkey | sudo tee /etc/wireguard/server_private.key > /dev/null
sudo cat /etc/wireguard/server_private.key | wg pubkey | sudo tee /etc/wireguard/server_public.key > /dev/null
sudo chmod 600 /etc/wireguard/server_private.key

# Get server private key
SERVER_PRIVATE_KEY=$(sudo cat /etc/wireguard/server_private.key)

# Create server configuration
echo "[INFO] Creating server configuration..."
sudo tee /etc/wireguard/wg0.conf > /dev/null << EOL
[Interface]
Address = 10.8.0.1/24
SaveConfig = true
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE_KEY
EOL

# Generate client keys
echo "[INFO] Generating client keys..."
sudo wg genkey | sudo tee /etc/wireguard/client_private.key > /dev/null
sudo cat /etc/wireguard/client_private.key | wg pubkey | sudo tee /etc/wireguard/client_public.key > /dev/null
sudo chmod 600 /etc/wireguard/client_private.key

# Add client peer to server config
CLIENT_PUBLIC_KEY=$(sudo cat /etc/wireguard/client_public.key)
sudo tee -a /etc/wireguard/wg0.conf > /dev/null << EOL

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.8.0.2/32
EOL

# Validate configuration before starting
echo "[INFO] Validating WireGuard configuration..."
if ! sudo wg-quick up wg0 --dry-run 2>/dev/null; then
    echo "[ERROR] Configuration validation failed. Checking for issues..."
    sudo cat /etc/wireguard/wg0.conf
    echo ""
    echo "[INFO] Attempting to fix common issues..."
    
    # Check if iptables is available
    if ! command -v iptables &> /dev/null; then
        echo "[INFO] Installing iptables..."
        sudo yum install -y iptables-services
    fi
    
    # Ensure proper network interface (some instances use ens5 instead of eth0)
    MAIN_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    echo "[INFO] Detected main network interface: $MAIN_INTERFACE"
    
    # Update config with correct interface
    sudo sed -i "s/eth0/$MAIN_INTERFACE/g" /etc/wireguard/wg0.conf
fi

# Start and enable WireGuard
echo "[INFO] Starting WireGuard service..."
sudo systemctl enable wg-quick@wg0

# Try to start the service and capture any errors
if sudo systemctl start wg-quick@wg0; then
    echo "[SUCCESS] WireGuard server started successfully"
else
    echo "[ERROR] Failed to start WireGuard server"
    echo "[INFO] Checking service status and logs..."
    sudo systemctl status wg-quick@wg0 --no-pager
    echo ""
    echo "[INFO] Recent log entries:"
    sudo journalctl -u wg-quick@wg0 --no-pager -n 20
    echo ""
    echo "[INFO] Attempting alternative startup method..."
    
    # Try manual startup to see exact error
    echo "[INFO] Manual startup attempt:"
    sudo wg-quick up wg0 || true
    
    exit 1
fi

echo "[SUCCESS] Server setup complete!"
EOF

# Copy and execute server setup script
print_status "Copying server setup script to EC2 instance..."
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no /tmp/wg-server-setup.sh ec2-user@"$EC2_IP":/tmp/

print_status "Executing server setup script on EC2 instance..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" "chmod +x /tmp/wg-server-setup.sh && /tmp/wg-server-setup.sh"

# Generate client configuration
print_status "Generating client configuration..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" << 'EOF'
SERVER_PUBLIC_KEY=$(sudo cat /etc/wireguard/server_public.key)
CLIENT_PRIVATE_KEY=$(sudo cat /etc/wireguard/client_private.key)
SERVER_IP="__SERVER_IP__"

sudo tee /etc/wireguard/client.conf > /dev/null << EOL
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.8.0.2/24
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOL
EOF

# Replace placeholder with actual server IP
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" "sudo sed -i 's/__SERVER_IP__/$EC2_IP/g' /etc/wireguard/client.conf"

# Download client configuration
print_status "Downloading client configuration..."
CLIENT_CONFIG_FILE="./${CLIENT_NAME}-wg.conf"
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP":/etc/wireguard/client.conf "$CLIENT_CONFIG_FILE"

# Verify server status
print_status "Verifying server status..."
SERVER_STATUS=$(ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" "sudo systemctl is-active wg-quick@wg0")

if [ "$SERVER_STATUS" = "active" ]; then
    print_success "WireGuard server is running successfully!"
else
    print_warning "Server status: $SERVER_STATUS"
fi

# Show server information
print_status "Getting server information..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no ec2-user@"$EC2_IP" << 'EOF'
echo "[INFO] Server interface status:"
sudo wg show
echo ""
echo "[INFO] Server listening on:"
sudo ss -ulpn | grep :51820 || echo "WireGuard not listening (this might be normal)"
EOF

# Cleanup temporary files
rm -f /tmp/wg-server-setup.sh

print_success "Setup completed successfully!"
echo ""
echo "===================================="
echo "SETUP SUMMARY"
echo "===================================="
echo "Server IP: $EC2_IP"
echo "WireGuard Port: $WG_PORT"
echo "VPN Subnet: $VPN_SUBNET.0/24"
echo "Server Address: $VPN_SUBNET.1"
echo "Client Address: $VPN_SUBNET.2"
echo ""
echo "Client configuration saved to: $CLIENT_CONFIG_FILE"
echo ""
echo "===================================="
echo "NEXT STEPS"
echo "===================================="
echo "1. Install WireGuard on your local machine:"
echo "   macOS: brew install wireguard-tools"
echo "   or download from Mac App Store"
echo ""
echo "2. Connect using one of these methods:"
echo ""
echo "   Method 1 - WireGuard App (GUI):"
echo "   - Open WireGuard app"
echo "   - Import tunnel from file: $CLIENT_CONFIG_FILE"
echo "   - Activate the tunnel"
echo ""
echo "   Method 2 - Command Line:"
echo "   sudo wg-quick up $CLIENT_CONFIG_FILE"
echo "   sudo wg-quick down $CLIENT_CONFIG_FILE  # to disconnect"
echo ""
echo "3. Test your connection:"
echo "   curl ifconfig.me  # Should show your EC2 IP"
echo ""
echo "===================================="
echo "TROUBLESHOOTING"
echo "===================================="
echo "- Check server logs: ssh -i $SSH_KEY ec2-user@$EC2_IP 'sudo journalctl -u wg-quick@wg0 -f'"
echo "- Restart server: ssh -i $SSH_KEY ec2-user@$EC2_IP 'sudo systemctl restart wg-quick@wg0'"
echo "- Check connection: sudo wg show"
echo ""

print_success "WireGuard VPN setup is complete!"

