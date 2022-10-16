#!/usr/bin/env python3
from botocore.exceptions import ClientError

from env import *

import logging
import boto3

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

_ec2 = boto3.resource('ec2', AWSSOCKS_REGION)


def awssocks_security_group_id():
    try:
        all_sg_list = _ec2.security_groups.all()
        awssocks_sg_list = [group for group in all_sg_list if group.description == AWSSOCKS_SECURITY_GROUP_NAME]
        awssocks_sg_id = awssocks_sg_list[0].id if awssocks_sg_list else None
        return awssocks_sg_id
    except ClientError:
        logging.exception("The search for the security group %s has failed.", AWSSOCKS_SECURITY_GROUP_NAME)
        raise


def delete_awssocks_security_group():
    try:
        group_id = awssocks_security_group_id()
        if group_id:
            logging.info("Deleting security group %s.", AWSSOCKS_SECURITY_GROUP_NAME)
            _ec2.SecurityGroup(group_id).delete()
            logger.info("The security group %s has been successfully deleted.", group_id)
    except ClientError:
        logging.exception("The deletion of the security group %s has failed.", AWSSOCKS_SECURITY_GROUP_NAME)
        raise


def create_awssocks_security_group():
    try:
        logging.info("Creating a security group named %s.", AWSSOCKS_SECURITY_GROUP_NAME)
        security_group = _ec2.create_security_group(
            Description=AWSSOCKS_SECURITY_GROUP_NAME,
            GroupName=AWSSOCKS_SECURITY_GROUP_NAME,
            TagSpecifications=[
                {
                    'ResourceType': 'security-group',
                    'Tags': [
                        {
                            'Key': 'AWSSOCKS__MANAGED',
                            'Value': 'True'
                        },
                    ]
                },
            ],
        )
        security_group.authorize_ingress(
            CidrIp='0.0.0.0/0',
            FromPort=22,
            ToPort=22,
            IpProtocol='tcp',
        )
        logging.info("The security group %s has been successfully created.", AWSSOCKS_SECURITY_GROUP_NAME)
        return awssocks_security_group_id()
    except ClientError:
        logging.exception("The creation of the security group %s has failed.", AWSSOCKS_SECURITY_GROUP_NAME)
        raise


def init_awssocks_security_group():
    logging.info("Verifying the configuration of the security group %s.", AWSSOCKS_SECURITY_GROUP_NAME)
    group_id = awssocks_security_group_id()
    if group_id is None:
        group_id = create_awssocks_security_group()
    logging.info("The verification of the security group %s configuration has been completed (%s)",
                 AWSSOCKS_SECURITY_GROUP_NAME, group_id)
    return group_id


if __name__ == '__main__':
    log_configuration()
    init_awssocks_security_group()
