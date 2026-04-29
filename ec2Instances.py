#!/usr/bin/env python3

import boto3
from botocore.exceptions import ClientError
from env import *
from loggerFactory import logger_factory

logger = logger_factory(__name__)

_ec2 = boto3.resource('ec2', region_name=AWSSOCKS_REGION)


def awssocks_create_instance(
        image_id, instance_type_list, key_name, security_group_ids=None, terminate_instance_after_minutes=None):
    try:

        instance_params = {'ImageId': image_id, 'KeyName': key_name}

        if terminate_instance_after_minutes is not None and terminate_instance_after_minutes >= 0:
            userdata = f"#!/bin/bash\n nohup shutdown -h +{terminate_instance_after_minutes} & \n"
            instance_params['UserData'] = userdata

        if security_group_ids is not None:
            instance_params['SecurityGroupIds'] = security_group_ids

        def create_instance(instance_size):
            try:
                logger.info("Trying %s to create an instance. Using the following parameters: %s.",
                            instance_size, str(instance_params))
                return _ec2.create_instances(**instance_params, InstanceType=instance_size, MinCount=1, MaxCount=1, InstanceInitiatedShutdownBehavior='terminate')[0]
            except ClientError as e:
                logger.info("Could not create an instance using %s. The instance type %s might not be available in the region %s.",
                            instance_size, instance_size, AWSSOCKS_REGION)
                raise e

        logger.info(
            "Trying to create an instance with one of the following sizes: %s. In case an instance type is not available, the next one will be tried.", ', '.join(instance_type_list))

        awssocks_instance = _call_function(create_instance, instance_type_list)
        awssocks_instance.create_tags(Tags=[
            {
                'Key': 'AWSSOCKS__MANAGED',
                'Value': 'True'
            },
            {
                'Key': 'AWSSOCKS__AUTO_TERMINATION_AFTER_MINUTES',
                'Value': str(terminate_instance_after_minutes)
            }
        ])
        logger.info("The instance %s has been successfully created.",
                    awssocks_instance.id)
        logger.info(
            "Please wait while the newly created instance is starting up and becoming operational.")
        awssocks_instance.wait_until_running()
        awssocks_instance.load()
        logger.info("The newly created instance %s is now fully operational and ready for use.",
                    awssocks_instance.id)
    except ClientError as e:
        logger.info(
            "An error occurred while creating the instance using instance size %s, image %s, and key %s.",
            image_id, str(instance_type_list), key_name)
        raise e
    else:
        return awssocks_instance


def awssocks_terminate_instance(instance_id):
    try:
        instance = _ec2.Instance(instance_id)
        instance.load()
        if instance.state["Name"] != 'terminated':
            logger.info("The instance %s is being terminated.", instance_id)
            instance.terminate()
            logger.info(
                "Please wait until the termination of instance %s has been completed.", instance_id)
            instance.load()
            instance.wait_until_terminated()
            logger.info(
                "The instance %s has been successfully terminated.", instance_id)
    except ClientError:
        logger.exception("Couldn't terminate instance %s.", instance_id)
        raise


def list_awssocks_instances():
    try:
        awssocks_instance_list_raw = _ec2.instances.filter(
            Filters=[
                {
                    'Name': 'tag:AWSSOCKS__MANAGED',
                    'Values': [
                        'True'
                    ]
                }
            ]
        )
        awssocks_instance_list = [
            instance for instance in awssocks_instance_list_raw]
        logger.info(
            f'Instances that have the tag AWSSOCKS__MANAGED set to True:')
        if len(awssocks_instance_list) > 0:
            for awssocks_instance in awssocks_instance_list:
                logger.info(
                    f'  - {awssocks_instance.id} {awssocks_instance.public_ip_address} {awssocks_instance.state["Name"]}')
        else:
            logger.info(f'  N/A ')

        return [awssocks_instance.id for awssocks_instance in awssocks_instance_list]
    except ClientError:
        logger.exception("Couldn't lookup instances.")
        raise


def list_awssocks_running_instances():
    try:
        awssocks_instance_list_raw = _ec2.instances.filter(
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
        awssocks_instance_list = [
            instance for instance in awssocks_instance_list_raw]
        logger.info(
            f'Running instances that have the tag AWSSOCKS__MANAGED set to True:')
        if len(awssocks_instance_list) > 0:
            for awssocks_instance in awssocks_instance_list:
                logger.info(
                    f'  - {awssocks_instance.id} {awssocks_instance.public_ip_address} {awssocks_instance.state["Name"]}')
        else:
            logger.info(f'  N/A ')
        return [awssocks_instance.id for awssocks_instance in awssocks_instance_list]
    except ClientError:
        logger.exception("Couldn't lookup instances.")
        raise


def awssocks_instance_ip_address(instance_id):
    instance = _ec2.Instance(instance_id)
    public_ip = instance.public_ip_address
    logger.info("The IP address for %s is %s.", instance_id, public_ip)
    return public_ip


def awssocks_instance_state(instance_id):
    instance = _ec2.Instance(instance_id)
    state = instance.state["Name"]
    logger.info("The State for %s is %s.", instance_id, state)
    return state


def _call_function(function, function_parameter_candidate_list):
    last_exception = None

    for param in function_parameter_candidate_list:
        try:
            return function(param)
        except Exception as e:
            last_exception = e

    if last_exception:
        raise last_exception
    else:
        raise ValueError(
            "The parameter list is empty, no function call was attempted.")
