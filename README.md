## Content of this repository

This repository holds two Python scripts that set up an AWS EC2 instance and tear down the instance.

The first script will perform the following tasks:

* Install a public key in an AWS region.
* Configure a security group.
* Launch a Nano EC2 instance using the public key and security group provided in the previous step.
* Output an ssh command to start an SOCKS proxy using the EC2 instance as target.

The purpose of the second script is to shut down the EC2 instance.

## Disclaimer

***Please note that these scripts come with absolutely no guarantees, and you use them at your own risk. Running this
code may result in charges to your AWS account.***

## Preconditions

To proceed, you need an AWS account and must have your default credentials configured as described in
the [AWS Tools and SDKs Shared Configuration and
Credentials Reference Guide](https://docs.aws.amazon.com/credref/latest/refdocs/creds-config-files.html).

You will need an SSH key. To generate one, use the `ssh-keygen` command. You can easily find a tutorial online to learn
how to use it.

Additionally, Python 3 must be installed on your machine.

## Setup

The steps to use this repository are as follows:

* Clone the project
* Change directory into the cloned project by using the `cd` command.
* Copy `env.py_template` to `env.py` and update the values for the SSH key name and AWS region in the newly created
  file.
* Create a virtual Python environment: `python3 -m venv venv`.
* Activate the environment: `source venv/bin/activate`
* Install the requirements: `pip install -r requirements.txt`.
* Run `START.py`, which will start the EC2 instance. The script will provide an SSH command, which you should execute to
  start the SOCKS tunnel.
* Configure your browser to use `localhost:4444` as the SOCKSv5 proxy. Also, ensure that you have selected the option `Proxy DNS when using SOCKS v5` in your browser's proxy settings. Please refer to the browser's documentation to learn how to do this.

You can now browse the web in your selected region without GeoIP restrictions.

To shut down the EC2 instance, simply run the `STOP.py` script. Alternatively, you have the option to set a time-to-live value in the _env.py_ file. When configured, the instance will automatically terminate itself after the specified period has elapsed (BETA feature).

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
        INFO: Creating a security group named proxy_security_group.
        INFO: The security group proxy_security_group has been successfully created.
        INFO: The verification of the security group proxy_security_group configuration has been completed (sg-0a5cec1b6d390ee34)
        INFO: Verifying the configuration of the public key id_rsa.
        INFO: Uploading the key proxy_public_key.
        INFO: The key proxy_public_key has been successfully uploaded (ec2.KeyPairInfo(name='proxy_public_key')).
        INFO: The key proxy_public_key with fingerprint 42:fc:74:51:2f:8b:62:9b:fb:8a:54:0f:d4:e3:7e:b4 has been found.
        INFO: The verification of the public key id_rsa configuration has been completed (proxy_public_key)
        INFO: Creating an instance using the following parameters: {'ImageId': 'ami-0b2e759b077980407', 'InstanceType': 't2.micro', 'KeyName': 'proxy_public_key', 'SecurityGroupIds': ['sg-0a5cec1b6d390ee34']}).
        INFO: The instance i-0ccd4cb047d744781 has been successfully created.
        INFO: Please wait while the newly created instance is starting up and becoming operational.
        INFO: The newly created instance i-0ccd4cb047d744781 is now fully operational and ready for use.
        INFO: The IP address for i-0ccd4cb047d744781 is 13.41.70.170.
        INFO: The State for i-0ccd4cb047d744781 is running.
        INFO: Summary:
        INFO:  - instance id is  i-0ccd4cb047d744781
        INFO:  - public ip is 13.41.70.170
        INFO:  - state is running
        INFO: ----------------------------------------------------------------------------------------
        INFO: STARTED
        INFO: ----------------------------------------------------------------------------------------
        INFO: Ready to create an ssh socks tunnel. Please execute the following command on the command line:
        INFO:     ssh -o "StrictHostKeyChecking no" -C -N  -i ~/.ssh/id_rsa  ec2-user@13.41.70.170 -D 4444

### Stop

         ./STOP.py 
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
        INFO:   - i-0ccd4cb047d744781 13.41.70.170 running
        INFO: The instance i-0ccd4cb047d744781 is being terminated.
        INFO: Please wait until the termination of instance i-0ccd4cb047d744781 has been completed.
        INFO: The instance i-0ccd4cb047d744781 has been successfully terminated.
        INFO: ----------------------------------------------------------------------------------------
        INFO: STOPPED

## Links

* AWS account creation: https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/
* AWS CLI setup: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* Some boto3 Python examples: https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/python
