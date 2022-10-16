#!/usr/bin/env python3
import boto3
import os
from botocore.exceptions import ClientError

from env import *

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

_ec2 = boto3.resource('ec2', region_name=AWSSOCKS_REGION)


def awssocks_public_key():
    try:
        all_key_pair_list = _ec2.key_pairs.all()
        for key_pair in all_key_pair_list:
            if key_pair.key_name == AWSSOCKS_KEY_NAME:
                logging.info("The key %s with fingerprint %s has been found.", AWSSOCKS_KEY_NAME,
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
            logging.info("Deleting the key %s.", AWSSOCKS_KEY_NAME)
            _ec2.KeyPair(AWSSOCKS_KEY_NAME).delete()
            logging.info("The key %s has been successfully deleted.", AWSSOCKS_KEY_NAME)
    except ClientError:
        logging.exception("The deletion of the key %s has failed.", AWSSOCKS_KEY_NAME)
        raise


def upload_awssocks_public_key():
    try:
        key = awssocks_public_key()
        if key is None:
            logging.info("Uploading the key %s.", AWSSOCKS_KEY_NAME)
            with open(os.path.expanduser("~") + "/.ssh/" + AWSSOCKS_KEY + ".pub", 'r') as file:
                key_data = file.read().strip()
                response = _ec2.import_key_pair(
                    KeyName=AWSSOCKS_KEY_NAME,
                    PublicKeyMaterial=key_data
                )
                logging.info("The key %s has been successfully uploaded (%s).", AWSSOCKS_KEY_NAME, str(response))
                key = awssocks_public_key()
        return key
    except ClientError:
        logging.exception("The upload of the key %s has failed.", AWSSOCKS_KEY)
        raise


def init_awssocks_public_key():
    logging.info("Verifying the configuration of the public key %s.", AWSSOCKS_KEY)
    key = awssocks_public_key()
    if key is None:
        key = upload_awssocks_public_key()
    logging.info("The verification of the public key %s configuration has been completed (%s)", AWSSOCKS_KEY, key)
    return AWSSOCKS_KEY_NAME


if __name__ == '__main__':
    log_configuration()
    upload_awssocks_public_key()
