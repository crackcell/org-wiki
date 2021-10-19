import glob
from absl import logging


def parse_dir(config):
    forge_dir = config['forge_dir']
    logging.debug(f'parsing forge: {forge_dir}')

    org_files = glob.glob(f'{forge_dir}/**/*.org', recursive=True)
    logging.debug(f'org files: {org_files}')

    return org_files
