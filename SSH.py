#!/usr/bin/env python3

import subprocess
import signal
import time
from ec2Instances import list_awssocks_running_instances, awssocks_instance_ip_address, awssocks_instance_state
from env import AWSSOCKS_KEY, AWSSOCKS_LOCAL_SSH_PORT, log_configuration
from loggerFactory import logger_factory

logger = logger_factory(__name__)


def check_instance_status():
    instance_ids = list_awssocks_running_instances()

    if not instance_ids:
        logger.info("No EC2 instances found.")
        return None

    return instance_ids[0]


def start_ssh_tunnel(instance_id):
    public_ip = awssocks_instance_ip_address(instance_id)
    ssh_command = [
        'ssh',
        '-o', 'StrictHostKeyChecking=no',
        '-C', '-N',
        '-i', f'~/.ssh/{AWSSOCKS_KEY}',
        f'ec2-user@{public_ip}',
        '-D', f'{AWSSOCKS_LOCAL_SSH_PORT}'
    ]

    logger.info("Executing SSH command: %s", ' '.join(ssh_command))

    process = subprocess.Popen(ssh_command)

    def signal_handler(sig, frame):
        logger.info("Terminating SSH tunnel...")
        process.terminate()
        process.wait()
        logger.info("...SSH tunnel closed")
        logger.info('-' * 42)
        logger.info("SSH TUNNEL")
        logger.info('-' * 42)

        exit(0)

    signal.signal(signal.SIGINT, signal_handler)

    while True:
        time.sleep(1)


def main():
    logger.info('=' * 42)
    logger.info("SSH TUNNEL")
    logger.info('-' * 42)
    log_configuration()
    instance = check_instance_status()

    if instance:
        start_ssh_tunnel(instance)

    logger.info('-' * 42)
    logger.info("SSH TUNNEL")
    logger.info('-' * 42)


if __name__ == '__main__':
    main()
