#!/usr/bin/env python3
import os

import boto3
from botocore.exceptions import ClientError
from env import *

logger = logger_factory(__name__)

_ec2 = boto3.resource('ec2', region_name=AWSSOCKS_REGION)


def awssocks_public_key():
    try:
        all_key_pair_list = _ec2.key_pairs.all()
        for key_pair in all_key_pair_list:
            if key_pair.key_name == AWSSOCKS_KEY_NAME:
                logger.info("The key %s with fingerprint %s has been found.", AWSSOCKS_KEY_NAME,
                            key_pair.key_fingerprint)
                return key_pair.key_name
        return None
    except ClientError:
        logging.exception("The search for the key %s has failed.", AWSSOCKS_KEY_NAME)
        raise


def delete_awssocks_public_key():
    try:
        public_key = awssocks_public_key()
        if public_key:
            logger.info("Deleting the key %s.", AWSSOCKS_KEY_NAME)
            _ec2.KeyPair(AWSSOCKS_KEY_NAME).delete()
            logger.info("The key %s has been successfully deleted.", AWSSOCKS_KEY_NAME)
    except ClientError:
        logger.exception("The deletion of the key %s has failed.", AWSSOCKS_KEY_NAME)
        raise


def upload_awssocks_public_key():
    try:
        key = awssocks_public_key()
        if key is None:
            key_file = os.path.expanduser("~") + "/.ssh/" + AWSSOCKS_KEY + ".pub"
            logger.info("Uploading the key file %s to AWS %s.", key_file, AWSSOCKS_KEY_NAME)
            with open(key_file, 'r') as file:
                key_data = file.read().strip()
                response = _ec2.import_key_pair(
                    KeyName=AWSSOCKS_KEY_NAME,
                    PublicKeyMaterial=key_data
                )
                logger.info("The key file %s has been successfully uploaded (%s).", key_file, str(response))
                key = awssocks_public_key()
        return key
    except ClientError:
        logger.exception("The upload of the key %s has failed.", AWSSOCKS_KEY)
        raise


def init_awssocks_public_key():
    logger.info("Verifying the configuration of the public key %s.", AWSSOCKS_KEY)
    key = awssocks_public_key()
    if key is None:
        key = upload_awssocks_public_key()
    logger.info("The verification of the public key %s configuration has been completed (%s)", AWSSOCKS_KEY, key)
    return AWSSOCKS_KEY_NAME


if __name__ == '__main__':
    log_configuration()
    upload_awssocks_public_key()
