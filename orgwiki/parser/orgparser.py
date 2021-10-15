import re

from absl import logging
from orgwiki.utils import raise_exception_and_log


def parse_file(org_file):
    if not org_file.endswith('.org'):
        raise_exception_and_log(f'invalid file: {org_file}')

    html_file = re.sub('org$', 'html', org_file)
    logging.debug(f'parsing: {org_file}, {html_file}')
