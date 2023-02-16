#!/usr/bin/env python3

from ec2Instances import list_awssocks_instances
from env import *
from loggerFactory import logger_factory
from publicKeys import awssocks_public_key
from securityGroups import awssocks_security_group_id

logger = logger_factory(__name__)


def status():
    logger.info('=' * 42)
    logger.info("STATUS")
    logger.info('-' * 42)

    log_configuration()
    list_awssocks_instances()
    logger.info("Installed security group: %s", awssocks_security_group_id())
    logger.info("Installed public key: %s", awssocks_public_key())

    logger.info('-' * 42)
    logger.info("STATUS")
    logger.info('-' * 42)


if __name__ == '__main__':
    status()
