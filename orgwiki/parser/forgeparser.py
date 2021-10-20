import glob

from absl import logging
from enum import Enum

class DocNode:

    class DocNodeType(Enum):
        CATEGORY = 1
        PAGE = 2


def parse_dir(config):
    forge_dir = config['forge_dir']
    logging.debug(f'parsing forge: {forge_dir}')

    org_files = glob.glob(f'{forge_dir}/**/*.org', recursive=True)
    logging.debug(f'org files: {org_files}')

    return org_files
