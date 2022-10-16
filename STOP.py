#!/usr/bin/env python3

from ec2Instances import list_awssocks_instances, awssocks_terminate_instance
from env import *
from loggerFactory import logger_factory
from publicKeys import delete_awssocks_public_key
from securityGroups import delete_awssocks_security_group

logger = logger_factory(__name__)


def stop():
    logger.info('=' * 42)
    logger.info("STOPPING")
    logger.info('-' * 42)

    log_configuration()
    awssocks_instance_list = list_awssocks_instances()
    for awssocks_instance in awssocks_instance_list:
        awssocks_terminate_instance(awssocks_instance)
    delete_awssocks_public_key()
    delete_awssocks_security_group()
    logger.info('-' * 42)
    logger.info("STOPPED")
    logger.info('-' * 42)


if __name__ == '__main__':
    stop()
