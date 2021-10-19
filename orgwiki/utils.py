import os.path
from absl import logging


def raise_exception_and_log(msg):
    logging.error(msg)
    raise Exception(msg)


def file_exists(path):
    return os.path.isfile(path)


def dir_exists(path):
    return os.path.isdir(path)
