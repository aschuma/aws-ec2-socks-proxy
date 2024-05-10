#!/usr/bin/env python3
import boto3
from botocore.exceptions import ClientError
from env import *
from loggerFactory import logger_factory

logger = logger_factory(__name__)

_ssm = boto3.client('ssm', AWSSOCKS_REGION)


def awssocks_ami_image():
    try:
        ami_paginator = _ssm.get_paginator("get_parameters_by_path")
        ami_params = []
        for page in ami_paginator.paginate(Path="/aws/service/ami-amazon-linux-latest"):
            ami_params += page["Parameters"]

        amzn2_amis_any_arch = [ap for ap in ami_params if
                               all(query in ap['Name'] for query
                                   in ('amzn2', 'gp2'))]

        amzn2_amis = [ap for ap in amzn2_amis_any_arch if
                      ap['Name'] in AWSSOCKS_EC2_ARCHITECTURE]

        if len(amzn2_amis) > 0:
            ami_image_id = amzn2_amis[0]['Value']
            logger.info("Found an Amazon Machine Image (AMI) that includes Amazon Linux 2, "
                        "an x64 architecture, and a general-purpose EBS volume: %s",
                        str(amzn2_amis[0]))
            return ami_image_id
        elif len(amzn2_amis_any_arch) > 0:
            ami_image_id = amzn2_amis_any_arch[0]['Value']
            logger.info("Found an Amazon Machine Image (AMI) that includes Amazon Linux 2, "
                        "and a general-purpose EBS volume: %s",
                        str(amzn2_amis_any_arch[0]))
            return ami_image_id
        elif len(ami_params) > 0:
            ami_image_id = ami_params[0]['Value']
            logger.info("Found an Amazon Machine Image (AMI) to use for the proxy: %s",
                        str(ami_params[0]))
            return ami_image_id
        else:
            raise RuntimeError(
                "Couldn't find any AMIs. Try a different path or find one in the "
                "AWS Management Console.")
    except ClientError:
        logger.exception("AMI - Lookup failed")
        raise


if __name__ == '__main__':
    log_configuration()
    print(awssocks_ami_image())
