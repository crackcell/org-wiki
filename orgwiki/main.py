#!/usr/bin/env python3

import yaml

from absl import app
from absl import flags
from absl import logging

from orgwiki.parser import forgeparser
from orgwiki.parser import orgparser

FLAGS = flags.FLAGS

flags.DEFINE_string('config', None, 'config file.')
flags.DEFINE_boolean('debug', False, 'show debug info.')


def main(argv):
    header = '''
                            __ __     __ 
.-----.----.-----.--.--.--.|__|  |--.|__|
|  _  |   _|  _  |  |  |  ||  |    < |  |
|_____|__| |___  |________||__|__|__||__|
           |_____| 

org-wiki: static wiki generator.'''

    logging.info(header)

    if FLAGS.config is None:
        logging.error('No config')
        exit(-1)

    if FLAGS.debug:
        logging.set_verbosity(logging.DEBUG)
        logging.debug(f'config file: {FLAGS.config}')

    config = parse_config_file(FLAGS.config)
    if FLAGS.debug:
        logging.debug(f'config: {config}')

    org_files = forgeparser.parse_dir(config)

    for org_file in org_files:
        orgparser.parse_file(org_file)


def parse_config_file(path):
    with open(path, 'r') as file:
        try:
            return yaml.safe_load(file)
        except yaml.YAMLError as err:
            logging.error(err)


if __name__ == '__main__':
    app.run(main)