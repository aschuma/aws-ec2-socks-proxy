
Sometimes, it is necessary to browse the Internet with privacy, 
access content that is restricted by geography. 
A VPN can help achieve this, but it requires either installing client software or subscribing
to a VPN service.

A more straightforward alternative is to use an encrypted SOCKS 
proxy tunnel, which allows you to route your local network traffic 
securely. When you use this proxy, all your applications will connect
to an SSH server, which will forward the traffic to its intended 
destination. As a result third parties
will not be able to monitor your traffic or restrict access to websites.

This can be achieved as follows.

* Set up an EC2 instance on AWS in the region where you wish to access geopip protected content.
* Establish a secure SSH tunnel from your local machine to the EC2 instance, forwarding traffic on port 4444.
* The following SSH command is used to configure a SOCKS proxy on the local server, which forwards all traffic to the EC2 instance. 

      ssh -o "StrictHostKeyChecking no" -C -N -i ~/.ssh/id_rsa ec2-user@18.133.223.240 -D 4444 

* In this scenario, the EC2 instance is located at IP address `18.133.223.240`.
* The SSH key being used is located at `~/.ssh/id_rsa` on the local machine. 
* On the local machine, the SOCKS proxy has been set up to listen on port `4444`.
* Configure your browser to use `localhost:4444` as the SOCKS proxy.

## Content of this repository

This repository holds Python scripts that set up an AWS EC2 instance and tear down the instance. 

The first script will perform the following tasks:

* Install a public key in the AWS region.
* Configure a security group.
* Launch a nano EC2 instance.
* Output an ssh command to start the SOCKS proxy.

The purpose of the second script is to shut down the EC2 instance.

## Disclaimer

***Please be advised that these scripts come with no guarantees, and you use them at your own risk.***

## Preconditions

To utilize these scripts, you will need to have the following tools/artifacts installed on your computer:

* AWS CLI SDK (refer to the AWS CLI documentation for more information)
* An SSH key generated with the ssh-keygen command
* Python3

## Setup

The steps to use this repository are as follows:

* Clone the project
* Copy `env.py_template` to `env.py` and update the values for the SSH key name and AWS region in the newly created
  file.
* Create a virtual Python environment: `python3 -m venv`.
* Install the requirements: `pip install requirements.txt`.
* Activate the environment: `source venv/bin/activate`
* Run `START.py`, which will start the EC2 instance. The script will provide an SSH command, which you should execute to
  start the SOCKS tunnel.
* Configure your browser to use `localhost:4444` as the SOCKS proxy.

You can now browse the web in your selected region without GeoIP restrictions.

To shut down the proxy, simply run the `STOP.py` script.

## Example script output

### Start

        ❯ ./START.py              
        INFO: Found credentials in shared credentials file: ~/.aws/credentials
        INFO: ========================================================================================
        INFO: STARTING
        INFO: ----------------------------------------------------------------------------------------
        INFO:
        
                            AWSSOCKS_KEY = id_rsa
                         AWSSOCKS_REGION = eu-west-2
              AWSSOCKS_EC2_INSTANCE_SIZE = t2.nano
                       AWSSOCKS_KEY_NAME = proxy_public_key
            AWSSOCKS_SECURITY_GROUP_NAME = proxy_security_group
        
        
        INFO: Instances that have the tag AWSSOCKS__MANAGED set to True:
        INFO: Found an Amazon Machine Image (AMI) that includes Amazon Linux 2, an x64 architecture, and a general-purpose EBS volume.
        INFO: {'Name': '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2', 'Type': 'String', 'Value': 'ami-0b2e759b077980407', 'Version': 77, 'LastModifiedDate': datetime.datetime(2023, 1, 26, 21, 43, 2, 625000, tzinfo=tzlocal()), 'ARN': 'arn:aws:ssm:eu-west-2::parameter/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2', 'DataType': 'text'}
        INFO: Verifying the configuration of the security group proxy_security_group.
        INFO: The verification of the security group proxy_security_group configuration has been completed (sg-0019af4a5367fa7d1)
        INFO: Verifying the configuration of the public key id_rsa.
        INFO: The key proxy_public_key with fingerprint 42:fc:74:51:2f:8b:62:9b:fb:8a:54:0f:d4:e3:7e:b4 has been found.
        INFO: The verification of the public key id_rsa configuration has been completed (proxy_public_key)
        INFO: Creating an instance using the following parameters: {'ImageId': 'ami-0b2e759b077980407', 'InstanceType': 't2.micro', 'KeyName': 'proxy_public_key', 'SecurityGroupIds': ['sg-0019af4a5367fa7d1']}).
        INFO: The instance i-024546de3d47d7d41 has been successfully created.
        INFO: Please wait while the newly created instance is starting up and becoming operational.
        INFO: The newly created instance i-024546de3d47d7d41 is now fully operational and ready for use.
        INFO: The IP address for i-024546de3d47d7d41 is 18.133.223.240.
        INFO: The State for i-024546de3d47d7d41 is running.
        INFO: Summary:
        INFO:  - instance id is  i-024546de3d47d7d41
        INFO:  - public ip is 18.133.223.240
        INFO:  - state is running
        INFO: ----------------------------------------------------------------------------------------
        INFO: STARTED
        INFO: ----------------------------------------------------------------------------------------
        INFO: Ready to create an ssh socks tunnel:
        INFO:     ssh -o "StrictHostKeyChecking no" -C -N  -i ~/.ssh/id_rsa  ec2-user@18.133.223.240 -D 4444

### Stop

        ❯ ./STOP.py
        INFO: Found credentials in shared credentials file: ~/.aws/credentials
        INFO: ========================================================================================
        INFO: STOPPING
        INFO: ----------------------------------------------------------------------------------------
        INFO:
        
                            AWSSOCKS_KEY = id_rsa
                         AWSSOCKS_REGION = eu-west-2
              AWSSOCKS_EC2_INSTANCE_SIZE = t2.nano
                       AWSSOCKS_KEY_NAME = proxy_public_key
            AWSSOCKS_SECURITY_GROUP_NAME = proxy_security_group
        
        
        INFO: Instances that have the tag AWSSOCKS__MANAGED set to True:
        INFO:   - i-024546de3d47d7d41 18.133.223.240 running
        INFO: The instance i-024546de3d47d7d41 is being terminated.
        INFO: Please wait until the termination of instance i-024546de3d47d7d41 has been completed.
        INFO: The instance i-024546de3d47d7d41 has been successfully terminated.
        INFO: ----------------------------------------------------------------------------------------
        INFO: STOPPED
        INFO: ----------------------------------------------------------------------------------------

## Links

* AWS account creation: https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/
* AWS CLI setup: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* Some boto3 Python examples: https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/python