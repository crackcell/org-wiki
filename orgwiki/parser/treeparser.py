import os
import re
import json

from absl import logging
from enum import Enum

from orgwiki import utils
from orgwiki.parser import orgparser


class DocNode:

    class NodeType(Enum):
        ROOT = 1
        CATEGORY = 2
        PAGE = 3

    def __init__(self, node_type=NodeType.PAGE, path=None, label='', fold=True):
        self.node_type = node_type
        self.children = []
        self.path = path
        self.label = label
        self.fold = fold

    def pprint(self, indent=0):
        indent_str = '-' * indent * 2
        type_str = 'root'
        if self.node_type == DocNode.NodeType.CATEGORY:
            type_str = 'cate'
        elif self.node_type == DocNode.NodeType.PAGE:
            type_str = 'page'
        print(f'{indent_str}{type_str}: label:{self.label}, fold:{self.fold}, path:{self.path}')
        for child in self.children:
            child.pprint(indent + 1)


class TreeParser:

    def __init__(self, forge_dir):
        self.forge_dir = forge_dir

    def parse(self):
        root = self.__parse_cate(self.forge_dir)
        root.node_type = DocNode.NodeType.ROOT
        return root

    def __parse_cate(self, path):
        logging.debug(f'parsing cate: {path}')
        node = DocNode(node_type=DocNode.NodeType.CATEGORY, path=path)
        meta = None

        with os.scandir(path) as it:
            for entry in it:
                if entry.is_dir():
                    cate_node = self.__parse_cate(entry.path)
                    node.children.append(cate_node)
                elif entry.name == 'META':
                    logging.debug(f'parsing meta: {entry.path}')
                    meta = self.__parse_cate_meta(entry.path)
                elif entry.name.endswith('.org'):
                    html_file = re.sub('org$', 'html', entry.path)
                    if not utils.file_exists(html_file):
                        logging.warning(f'missing html file of {entry.name}')
                    page_node = self.__parse_page(entry.path)
                    node.children.append(page_node)

        # parse meta
        if meta:
            label = meta.get('label')
            if label is not None:
                node.label = label
            fold = meta.get('fold')
            node.fold = False if fold == 0 else True
        else:
            node.label = os.path.basename(path)

        return node

    def __parse_page(self, path):
        logging.debug(f'parsing page: {path}')
        node = DocNode(node_type=DocNode.NodeType.PAGE, path=path)

        org_file = orgparser.parse_org_file(path)
        logging.debug(f'parsing org file: {org_file}')

        return node

    def __parse_cate_meta(self, path):
        with open(path, 'r') as f:
            return json.load(f)

