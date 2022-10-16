#!/usr/bin/env python3

from amiImages import awssocks_ami_image
from ec2Instances import awssocks_create_instance, list_awssocks_instances, awssocks_instance_ip_address, \
    awssocks_instance_state
from env import *
from publicKeys import init_awssocks_public_key
from securityGroups import init_awssocks_security_group

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


def start():
    logging.info('=' * 88)
    logging.info("STARTING")
    logging.info('-' * 88)

    log_configuration()
    list_awssocks_instances()
    image_id = awssocks_ami_image()
    security_group = init_awssocks_security_group()
    key_name = init_awssocks_public_key()

    awssocks_instance = awssocks_create_instance(
        image_id=image_id,
        instance_type='t2.micro',
        key_name=key_name,
        security_group_ids=[security_group])

    public_ip = awssocks_instance_ip_address(awssocks_instance.id)
    state = awssocks_instance_state(awssocks_instance.id)

    logging.info("Summary:")
    logging.info(" - instance id is  %s", awssocks_instance.id)
    logging.info(" - public ip is %s", public_ip)
    logging.info(" - state is %s", state)

    logging.info('-' * 88)
    logging.info("STARTED")
    logging.info('-' * 88)
    logging.info("Ready to create an ssh socks tunnel:")
    logging.info("    ssh -o \"StrictHostKeyChecking no\" -C -N  -i ~/.ssh/%s  ec2-user@%s -D 4444", AWSSOCKS_KEY,
                 public_ip)

    return awssocks_instance


if __name__ == '__main__':
    start()
