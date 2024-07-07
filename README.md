# SOCKSv5 proxy using an AWS EC2 instance as relay server

⚠️ Please note that the configuration has changed. Therefore, it is advisable to repeat the configuration steps in case you initiate a `git pull`.

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
Please consult also [Specify which AWS Regions your account can use](https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-regions.html)

You will need an SSH key. To generate one, use the `ssh-keygen` command. You can easily find a tutorial online to learn
how to use it.

Additionally, Python 3 must be installed on your machine.

## Setup

The steps to use this repository are as follows:

* Clone the project
* Change directory into the cloned project by using the `cd` command.
* Copy `config.ini_template` to `config.ini` and update the values for the SSH key name and AWS region in the newly created
  file.
* Create a virtual Python environment: `python3 -m venv venv`.
* Activate the environment: `source venv/bin/activate`
* Install the requirements: `pip install -r requirements.txt`.
* Run `START.py`, which will start the EC2 instance. The script will provide an SSH command, which you should execute to
  start the SOCKS tunnel.
* Configure your browser to use `localhost:4444` as the SOCKSv5 proxy. Also, ensure that you have selected the option `Proxy DNS when using SOCKS v5` in your browser's proxy settings. Please refer to the browser's documentation to learn how to do this. I use Firefox because it doesn't depend on the operating system's settings, allowing me to easily adjust the SOCKS proxy settings.

You can now browse the web in your selected region without GeoIP restrictions.

To shut down the EC2 instance, simply run the `STOP.py` script. Alternatively, you have the option to set a time-to-live value in the `config.ini` file. When configured, the instance will automatically terminate itself after the specified period has elapsed (BETA feature).

## Example script output

### Start

        ❯ ./START.py 
        21:26:44,320 INFO: Found credentials in shared credentials file: ~/.aws/credentials
        21:26:44,699 INFO: ==========================================
        21:26:44,699 INFO: STARTING
        21:26:44,699 INFO: ------------------------------------------
        21:26:44,699 INFO: 
            
                                    AWSSOCKS_KEY = id_rsa__aws_aschuma-std
                                 AWSSOCKS_REGION = eu-west-2
                      AWSSOCKS_EC2_INSTANCE_SIZE = t2.nano
                               AWSSOCKS_KEY_NAME = AWSSOCKS_KEY
                    AWSSOCKS_SECURITY_GROUP_NAME = AWSSOCKS_SG
         AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES = 180 (BETA feature)
            
            
        21:26:44,699 INFO: Instances that have the tag AWSSOCKS__MANAGED set to True:
        21:26:45,310 INFO: Found an Amazon Machine Image (AMI) that includes Amazon Linux 2, an x64 architecture, and a general-purpose EBS volume: {'Name': '/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2', 'Type': 'String', 'Value': 'ami-0d3718d9421324fb3', 'Version': 111, 'LastModifiedDate': datetime.datetime(2024, 4, 19, 0, 49, 24, 883000, tzinfo=tzlocal()), 'ARN': 'arn:aws:ssm:eu-west-2::parameter/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2', 'DataType': 'text'}
        21:26:45,310 INFO: Verifying the configuration of the security group AWSSOCKS_SG.
        21:26:45,644 INFO: Creating a security group named AWSSOCKS_SG.
        21:26:46,353 INFO: The security group AWSSOCKS_SG has been successfully created.
        21:26:46,661 INFO: The verification of the security group AWSSOCKS_SG configuration has been completed (sg-0ef89a67d14979626)
        21:26:46,661 INFO: Verifying the configuration of the public key id_rsa__aws_aschuma-std.
        21:26:46,965 INFO: Uploading the key file /Users/aschuma/.ssh/id_rsa__aws_aschuma-std.pub to AWS AWSSOCKS_KEY.
        21:26:47,133 INFO: The key file /Users/aschuma/.ssh/id_rsa__aws_aschuma-std.pub has been successfully uploaded (ec2.KeyPairInfo(name='AWSSOCKS_KEY')).
        21:26:47,208 INFO: The key AWSSOCKS_KEY with fingerprint 97:a0:42:36:4b:2b:d2:01:9e:36:43:da:d0:af:9e:08 has been found.
        21:26:47,209 INFO: The verification of the public key id_rsa__aws_aschuma-std configuration has been completed (AWSSOCKS_KEY)
        21:26:47,209 INFO: Creating an instance using the following parameters: {'ImageId': 'ami-0d3718d9421324fb3', 'InstanceType': 't2.nano', 'KeyName': 'AWSSOCKS_KEY', 'UserData': '#!/bin/bash\n nohup shutdown -h +180 & \n', 'SecurityGroupIds': ['sg-0ef89a67d14979626']}.
        21:26:48,709 INFO: The instance i-00a09f6a53325facb has been successfully created.
        21:26:48,710 INFO: Please wait while the newly created instance is starting up and becoming operational.
        21:27:19,453 INFO: The newly created instance i-00a09f6a53325facb is now fully operational and ready for use.
        21:27:19,570 INFO: The IP address for i-00a09f6a53325facb is 3.8.175.31.
        21:27:19,688 INFO: The State for i-00a09f6a53325facb is running.
        21:27:19,689 INFO: Summary:
        21:27:19,689 INFO:  - instance id is  i-00a09f6a53325facb
        21:27:19,689 INFO:  - public ip is 3.8.175.31
        21:27:19,689 INFO:  - state is running
        21:27:19,689 INFO: ------------------------------------------
        21:27:19,689 INFO: STARTED
        21:27:19,689 INFO: ------------------------------------------
        21:27:19,689 INFO: Ready to create an ssh socks tunnel. Please execute the following command on the command line:
        21:27:19,689 INFO:     ssh -o "StrictHostKeyChecking no" -C -N  -i ~/.ssh/id_rsa__aws_aschuma-std  ec2-user@3.8.175.31 -D 4444

### Stop

        ❯ ./STOP.py 
        21:31:33,806 INFO: Found credentials in shared credentials file: ~/.aws/credentials
        21:31:34,140 INFO: ==========================================
        21:31:34,140 INFO: STOPPING
        21:31:34,140 INFO: ------------------------------------------
        21:31:34,141 INFO: 
            
                                    AWSSOCKS_KEY = id_rsa__aws_aschuma-std
                                 AWSSOCKS_REGION = eu-west-2
                      AWSSOCKS_EC2_INSTANCE_SIZE = t2.nano
                               AWSSOCKS_KEY_NAME = AWSSOCKS_KEY
                    AWSSOCKS_SECURITY_GROUP_NAME = AWSSOCKS_SG
         AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES = 180 (BETA feature)
            
            
        21:31:34,141 INFO: Instances that have the tag AWSSOCKS__MANAGED set to True:
        21:31:34,592 INFO:   - i-00a09f6a53325facb 3.8.175.31 running
        21:31:34,824 INFO: The instance i-00a09f6a53325facb is being terminated.
        21:31:35,326 INFO: Please wait until the termination of instance i-00a09f6a53325facb has been completed.
        21:32:20,998 INFO: The instance i-00a09f6a53325facb has been successfully terminated.
        21:32:21,224 INFO: The key AWSSOCKS_KEY with fingerprint 97:a0:42:36:4b:2b:d2:01:9e:36:43:da:d0:af:9e:08 has been found.
        21:32:21,224 INFO: Deleting the key AWSSOCKS_KEY.
        21:32:21,388 INFO: The key AWSSOCKS_KEY has been successfully deleted.
        21:32:21,924 INFO: Deleting security group AWSSOCKS_SG.
        21:32:22,326 INFO: The security group sg-0ef89a67d14979626 has been successfully deleted.
        21:32:22,326 INFO: ------------------------------------------
        21:32:22,326 INFO: STOPPED
        21:32:22,326 INFO: ------------------------------------------

### Status

        ❯ ./STATUS.py
        21:40:42,777 INFO: Found credentials in shared credentials file: ~/.aws/credentials
        21:40:43,164 INFO: ==========================================
        21:40:43,164 INFO: STATUS
        21:40:43,164 INFO: ------------------------------------------
        21:40:43,165 INFO: 
            
                                    AWSSOCKS_KEY = id_rsa__aws_aschuma-std
                                 AWSSOCKS_REGION = eu-west-2
                      AWSSOCKS_EC2_INSTANCE_SIZE = t2.nano
                               AWSSOCKS_KEY_NAME = AWSSOCKS_KEY
                    AWSSOCKS_SECURITY_GROUP_NAME = AWSSOCKS_SG
         AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES = 180 (BETA feature)
            
            
        21:40:43,165 INFO: Instances that have the tag AWSSOCKS__MANAGED set to True:
        21:40:43,566 INFO:   - i-00a09f6a53325facb None terminated
        21:40:44,206 INFO: Installed security group: None
        21:40:44,444 INFO: Installed public key: None
        21:40:44,444 INFO: ------------------------------------------
        21:40:44,444 INFO: STATUS
        21:40:44,444 INFO: ------------------------------------------        

## Helper Scripts

The following scripts are optional helper scripts. Only `./START.py`, `./STOP.py`, and `./STATUS.py`, mentioned above, are necessary for starting, stopping, and checking the status of the AWS EC2 infrastructure.

The subsequent helper scripts provide additional functionality and may or may not be compatible with your operating system. They have been tested only on macOS.

### Configuration Manager

This script is a configuration manager designed to handle multiple configuration files. The available configuration files should be stored in a directory called `configs`. The script allows you to list these configurations, select one, and create a symbolic link named `current-config.ini` that points to the selected configuration file.

#### Key Features:

* **List Configurations**: Displays all available `.ini` configuration files in the `configs` directory.
* **Current Configuration**: Shows which configuration file is currently linked.
* **Select and Update**: Allows the user to select a configuration file and updates the symlink to point to the new configuration.

#### Usage:

Run the script directly to manage the configurations.

```bash
./CM.py
```


### SSH Tunnel Starter

This script is a utility designed to start an SSH tunnel, acting as a wrapper around the `ssh` command. It uses the IP address of the started EC2 instance and the SSH key specified in the configuration file to establish the tunnel (The script has been tested exclusively on macOS).

#### Key Features:

* **Check Instance Status**: Connects to AWS to find running EC2 instances tagged for use with this script.
* **Start SSH Tunnel**: Initiates an SSH tunnel to the selected EC2 instance using the specified SSH key.
* **Graceful Shutdown**: Handles termination signals to close the SSH tunnel gracefully.

#### Usage:

Run the script directly to start the SSH tunnel. It will automatically fetch the necessary details such as the instance's IP address and the SSH key from environment variables.

```bash
./SSH.py
```

## Links

* AWS account creation: https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/
* AWS manage entitled regions: https://docs.aws.amazon.com/accounts/latest/reference/manage-acct-regions.html
* AWS CLI setup: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
* Some boto3 Python examples: https://github.com/awsdocs/aws-doc-sdk-examples/tree/main/python
