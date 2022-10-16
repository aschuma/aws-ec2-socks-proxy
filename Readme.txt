This repository contains some bash scripts to set up a SOCKS proxy on a AWS EC2 instance. I am using that to bypass GeoIP blockers.

Requirements for the subsequent steps:
- AWS CLI SDK is installed on your computer, see also AWS CLI Docs
- Firefox is installed on your computer

Steps:
- Copy env.sh_template to env.sh, and change the name of the SSH key and the AWS region in env.sh.
- Run init.sh to install the SSH key in the selected region
- Run start.sh. This starts the EC2 instance
- Run startTunnelAndFirefox.sh (You should  adjust the script to change the path to Firefox)

Now you can surf the web in the selected region without a GeoIP blocker.

To shutdown the proxy:
- Run tearDown.sh to stop the EC2 instance again.

I'm not a bash expert at all, forgive my bad coding style :-)

!!! Caution: Use the scripts at your own risk !!!

