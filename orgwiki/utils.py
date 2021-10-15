from absl import logging


def raise_exception_and_log(msg):
    logging.error(msg)
    raise Exception(msg)
