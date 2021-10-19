import re
import os.path

from absl import logging
from orgwiki import utils


def parse_file(org_file, config):
    if not org_file.endswith('.org'):
        utils.raise_exception_and_log(f'invalid file: {org_file}')

    html_file = re.sub('org$', 'html', org_file)
    logging.debug(f'parsing: {org_file}, {html_file}')

    if not utils.file_exists(html_file):
        logging.warning(f'missing html file of {org_file}')
        return None

    cate_info = parse_category(org_file, config)

def parse_category(org_file, config):
    """
    parse category meta from path.

    :param org_file: org file path
    :param config:  config
    :return: array of category
    """

    logging.debug(f'parsing category meta from {org_file}')

    cate_str = org_file[len(config['forge_dir']):]
    cate_parts = [s for s in cate_str.split('/') if len(s) > 0]
    cate_parts = cate_parts[:-1]
    logging.debug(f'cate str: {cate_str} → cate parts: {cate_parts}')

    return cate_parts
