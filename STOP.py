#!/usr/bin/env python3

from ec2Instances import list_awssocks_instances, awssocks_terminate_instance
from env import *

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')


def stop():
    logging.info('=' * 88)
    logging.info("STOPPING")
    logging.info('-' * 88)

    log_configuration()
    awssocks_instance_list = list_awssocks_instances()
    for awssocks_instance in awssocks_instance_list:
        awssocks_terminate_instance(awssocks_instance)
    logging.info('-' * 88)
    logging.info("STOPPED")
    logging.info('-' * 88)


if __name__ == '__main__':
    stop()
