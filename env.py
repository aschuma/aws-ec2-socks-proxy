#!/usr/bin/env python3
from loggerFactory import logger_factory
import os
import configparser

logger = logger_factory(__name__)

# Read configuration from file
config = configparser.ConfigParser()

primary_config_path = 'current-config.ini'
fallback_config_path = 'config.ini'

if os.path.exists(primary_config_path):
    # Attempt to read the primary configuration file
    config.read(primary_config_path)
    logger.info(f"Configuration loaded from {primary_config_path}")
else:
    # Fallback to the secondary configuration file if the primary is not found
    config.read(fallback_config_path)
    logger.info(
        f"{primary_config_path} not found. Configuration loaded from {fallback_config_path}")

# Retrieve values with defaults from environemnt or config.ini, respecting environment variables
AWSSOCKS_KEY = os.getenv('AWSSOCKS_KEY', config.get(
    'awssocks', 'awssocks_key', fallback="my-whatever_rsa-key"))
AWSSOCKS_REGION = os.getenv('AWSSOCKS_REGION', config.get(
    'awssocks', 'awssocks_region', fallback="eu-west-2"))
AWSSOCKS_EC2_INSTANCE_SIZE = os.getenv('AWSSOCKS_EC2_INSTANCE_SIZE', config.get(
    'awssocks', 'awssocks_ec2_instance_size', fallback="t3.nano"))
AWSSOCKS_EC2_ARCHITECTURE = os.getenv('AWSSOCKS_EC2_ARCHITECTURE', config.get(
    'awssocks', 'awssocks_ec2_architecture', fallback="x86_64"))
AWSSOCKS_KEY_NAME = os.getenv('AWSSOCKS_KEY_NAME', config.get(
    'awssocks', 'awssocks_key_name', fallback="AWSSOCKS_KEY"))
AWSSOCKS_SECURITY_GROUP_NAME = os.getenv('AWSSOCKS_SECURITY_GROUP_NAME', config.get(
    'awssocks', 'awssocks_security_group_name', fallback="AWSSOCKS_SG"))
AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES = int(os.getenv('AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES', config.get(
    'awssocks', 'awssocks_auto_termination_after_minutes', fallback="-1")))
AWSSOCKS_LOCAL_SSH_PORT = int(os.getenv('AWSSOCKS_LOCAL_SSH_PORT', config.get(
    'awssocks', 'awssocks_local_ssh_port', fallback="4444")))


def log_configuration():
    logger.info("""
                            AWSSOCKS_KEY = {}
                         AWSSOCKS_REGION = {}
              AWSSOCKS_EC2_INSTANCE_SIZE = {} (candidates)
               AWSSOCKS_EC2_ARCHITECTURE = {} (preferred)
                       AWSSOCKS_KEY_NAME = {}
            AWSSOCKS_SECURITY_GROUP_NAME = {}
 AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES = {} (BETA feature)
                 AWSSOCKS_LOCAL_SSH_PORT = {}
    """.format(AWSSOCKS_KEY, AWSSOCKS_REGION, AWSSOCKS_EC2_INSTANCE_SIZE, AWSSOCKS_EC2_ARCHITECTURE,
               AWSSOCKS_KEY_NAME, AWSSOCKS_SECURITY_GROUP_NAME, AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES, AWSSOCKS_LOCAL_SSH_PORT))


if __name__ == '__main__':
    log_configuration()
