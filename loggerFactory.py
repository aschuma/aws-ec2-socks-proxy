#!/usr/bin/env python3
import logging


def logger_factory(name):
    logger = logging.getLogger(name)
    # logging_format = '%(asctime)s %(levelname)s {%(filename)s:%(lineno)d}: %(message)s'
    logging_format = '%(asctime)s %(levelname)s: %(message)s'
    logging.basicConfig(level=logging.INFO, format=logging_format)
    return logger
