import os
import re
import json

from absl import logging
from enum import Enum

from orgwiki import utils
from orgwiki.parser import org_parser


class DocTreeNodeType(Enum):
    ROOT = 1
    CATEGORY = 2
    PAGE = 3


class DocTreeNode:

    def __init__(self, node_type=DocTreeNodeType.PAGE, path=None, label='', fold=True):
        self.node_type = node_type
        self.children = []
        self.path = path
        self.label = label
        self.fold = fold

    def pprint(self, indent=1):

        type_str = 'root'
        indent_str = ' → ' * indent
        if self.node_type == DocTreeNodeType.CATEGORY:
            type_str = 'cate'
        elif self.node_type == DocTreeNodeType.PAGE:
            type_str = 'page'

        output = f'{indent_str}{type_str}: label:{self.label}, fold:{self.fold}, path:{self.path}\n'

        for child in self.children:
            output += child.pprint(indent + 1)

        return output


def parse(path):
    root = __parse_cate(path)
    root.node_type = DocTreeNodeType.ROOT
    logging.debug(f'doc tree: \n{root.pprint()}')
    return root


def __parse_cate(path):
    logging.debug(f'parsing cate: {path}')
    node = DocTreeNode(node_type=DocTreeNodeType.CATEGORY, path=path)
    meta = None

    with os.scandir(path) as it:
        for entry in it:
            if entry.is_dir():
                cate_node = __parse_cate(entry.path)
                node.children.append(cate_node)
            elif entry.name == 'META':
                logging.debug(f'parsing meta: {entry.path}')
                meta = __parse_cate_meta(entry.path)
            elif entry.name.endswith('.org'):
                html_file = re.sub('org$', 'html', entry.path)
                if not utils.file_exists(html_file):
                    logging.warning(f'missing html file of {entry.name}')
                    continue
                page_node = __parse_page(entry.path)
                page_node.path = html_file
                node.children.append(page_node)

    # parse meta
    node.label = os.path.basename(path)
    if meta is not None:
        label = meta.get('label')
        if label is not None and len(label) > 0:
            node.label = label
        fold = meta.get('fold')
        node.fold = False if fold == 0 else True

    return node


def __parse_page(path):
    logging.debug(f'parsing page: {path}')
    node = DocTreeNode(node_type=DocTreeNodeType.PAGE, path=path)

    org_file = org_parser.parse_org_file(path)
    logging.debug(f'parsing org file: {org_file}')

    node.label = org_file.title if org_file.title else 'untitled'

    return node


def __parse_cate_meta(path):
    with open(path, 'r') as f:
        return json.load(f)
