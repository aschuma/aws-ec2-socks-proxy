#!/usr/bin/env python3

import boto3
from botocore.exceptions import ClientError

from env import *

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

_ec2 = boto3.resource('ec2', region_name=AWSSOCKS_REGION)


def awssocks_create_instance(
        image_id, instance_type, key_name, security_group_ids=None):
    """
    Creates a new Amazon EC2 instance. The instance automatically starts immediately after
    it is created.

    The instance is created in the default VPC of the current account.

    :param image_id: The Amazon Machine Image (AMI) that defines the kind of
                     instance to create. The AMI defines things like the kind of
                     operating system, such as Amazon Linux, and how the instance is
                     stored, such as Elastic Block Storage (EBS).
    :param instance_type: The type of instance to create, such as 't2.micro'.
                          The instance type defines things like the number of CPUs and
                          the amount of memory.
    :param key_name: The name of the key pair that is used to secure connections to
                     the instance.
    :param security_group_ids: A list of security groups ids that are used to grant
                                 access to the instance. When no security groups are
                                 specified, the default security group of the VPC
                                 is used.
    :return: The newly created instance.
    """
    try:
        instance_params = {
            'ImageId': image_id, 'InstanceType': instance_type, 'KeyName': key_name
        }
        if security_group_ids is not None:
            instance_params['SecurityGroupIds'] = security_group_ids
        logger.info("Creating an instance using the following parameters: %s).", str(instance_params))

        awssocks_instance = _ec2.create_instances(**instance_params, MinCount=1, MaxCount=1)[0]
        awssocks_instance.create_tags(Tags=[{
            'Key': 'AWSSOCKS__MANAGED',
            'Value': 'True'
        }])
        logger.info("The instance %s has been successfully created.", awssocks_instance.id)
        logging.info("Please wait while the newly created instance is starting up and becoming operational.")
        awssocks_instance.wait_until_running()
        awssocks_instance.load()
        logger.info("The newly created instance %s is now fully operational and ready for use.",
                    awssocks_instance.id)
    except ClientError:
        logging.exception(
            "Couldn't create instance with image %s, instance type %s, and key %s.",
            image_id, instance_type, key_name)
        raise
    else:
        return awssocks_instance


def awssocks_terminate_instance(instance_id):
    """
    Terminates an instance. The request returns immediately. To wait for the
    instance to terminate, use Instance.wait_until_terminated().

    :param instance_id: The ID of the instance to terminate.
    """
    try:
        instance = _ec2.Instance(instance_id)
        instance.load()
        if instance.state["Name"] != 'terminated':
            logger.info("The instance %s is being terminated.", instance_id)
            instance.terminate()
            logger.info("Please wait until the termination of instance %s has been completed.", instance_id)
            instance.load()
            instance.wait_until_terminated()
            logger.info("The instance %s has been successfully terminated.", instance_id)
    except ClientError:
        logging.exception("Couldn't terminate instance %s.", instance_id)
        raise


def list_awssocks_instances():
    try:
        awssocks_instance_list = _ec2.instances.filter(
            Filters=[
                {
                    'Name': 'tag:AWSSOCKS__MANAGED',
                    'Values': [
                        'True'
                    ]
                }
            ]
        )
        logging.info(f'Instances that have the tag AWSSOCKS__MANAGED set to True:')
        if awssocks_instance_list:
            for awssocks_instance in awssocks_instance_list:
                logging.info(
                    f'  - {awssocks_instance.id} {awssocks_instance.public_ip_address} {awssocks_instance.state["Name"]}')
        else:
            logging.info(f'  - none ')

        return [awssocks_instance.id for awssocks_instance in awssocks_instance_list]
    except ClientError:
        logging.exception("Couldn't lookup instances.")
        raise


def list_awssocks_running_instances():
    try:
        awssocks_instance_list = _ec2.instances.filter(
            Filters=[
                {
                    'Name': 'tag:AWSSOCKS__MANAGED',
                    'Values': [
                        'True'
                    ]
                },
                {
                    'Name': 'instance-state-name',
                    'Values': [
                        'running'
                    ]
                }
            ]
        )
        logging.info(f'Running instances that have the tag AWSSOCKS__MANAGED set to True:')
        if awssocks_instance_list:
            for awssocks_instance in awssocks_instance_list:
                logging.info(
                    f'  - {awssocks_instance.id} {awssocks_instance.public_ip_address} {awssocks_instance.state["Name"]}')
        else:
            logging.info(f'  - none ')
        return [awssocks_instance.id for awssocks_instance in awssocks_instance_list]
    except ClientError:
        logging.exception("Couldn't lookup instances.")
        raise


def awssocks_instance_ip_address(instance_id):
    instance = _ec2.Instance(instance_id)
    public_ip = instance.public_ip_address
    logging.info("The IP address for %s is %s.", instance_id, public_ip)
    return public_ip


def awssocks_instance_state(instance_id):
    instance = _ec2.Instance(instance_id)
    state = instance.state["Name"]
    logging.info("The State for %s is %s.", instance_id, state)
    return state
