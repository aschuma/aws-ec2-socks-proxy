This repository contains some bash scripts to set up a SOCKS proxy. I'am using that to bypass GeoIP blocker.

For this purpose, an AWS EC2 instance is started.

For The requirement steps the AWS CLI SDK has to be installed on your computer.

Steps:
1. Copy env.sh_template to env.sh, change the name of the SSH key and the AWS region in env.sh.
2. Run init.sh to install the SSH key in the selected region
3. Run start.sh. This starts the EC2 instance
4. Run startTunnelAndFirefox.sh (You should  adjust the script to change the path to Firefox)

Now you can surf the web in the selected region without a GeoIP blocker.

To shutdown the proxy:
5. Run tearDown.sh to stop the EC2 instance again.

I'm not a bash expert at all, forgive by bad coding style :-)

!!! Caution: Use the scripts at your own risk !!!




