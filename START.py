#!/usr/bin/env python3

from amiImages import awssocks_ami_image
from ec2Instances import awssocks_create_instance, list_awssocks_instances, awssocks_instance_ip_address, \
    awssocks_instance_state
from env import *
from loggerFactory import logger_factory
from publicKeys import init_awssocks_public_key
from securityGroups import init_awssocks_security_group

logger = logger_factory(__name__)


def start():
    logger.info('=' * 42)
    logger.info("STARTING")
    logger.info('-' * 42)

    log_configuration()
    list_awssocks_instances()
    image_id = awssocks_ami_image()
    security_group = init_awssocks_security_group()
    key_name = init_awssocks_public_key()
    instance_type_list = [type.strip()
                          for type in AWSSOCKS_EC2_INSTANCE_SIZE.split(',')]
    awssocks_instance = awssocks_create_instance(
        image_id=image_id,
        instance_type_list=instance_type_list,
        key_name=key_name,
        security_group_ids=[security_group],
        terminate_instance_after_minutes=AWSSOCKS_AUTO_TERMINATION_AFTER_MINUTES
    )

    public_ip = awssocks_instance_ip_address(awssocks_instance.id)
    state = awssocks_instance_state(awssocks_instance.id)

    logger.info("Summary:")
    logger.info(" - instance id is  %s", awssocks_instance.id)
    logger.info(" - public ip is %s", public_ip)
    logger.info(" - state is %s", state)

    logger.info('-' * 42)
    logger.info("STARTED")
    logger.info('-' * 42)
    logger.info(
        "Ready to create an ssh socks tunnel. Please execute the following command on the command line:")
    logger.info("    ssh -o \"StrictHostKeyChecking no\" -C -N  -i ~/.ssh/%s  ec2-user@%s -D %s",
                AWSSOCKS_KEY,
                public_ip,
                AWSSOCKS_LOCAL_SSH_PORT)

    return awssocks_instance


if __name__ == '__main__':
    start()
