import os
import re

from absl import logging
from enum import Enum

from orgwiki import utils


class DocNode:

    class NodeType(Enum):
        ROOT = 1
        CATEGORY = 2
        PAGE = 3

    def __init__(self, node_type=NodeType.PAGE):
        self.node_type = node_type
        self.children = []


class ForgeParser:

    def __init__(self, forge_dir):
        self.forge_dir = forge_dir

    def parse(self):
        root = DocNode(node_type=DocNode.NodeType.ROOT)
        logging.info(f'start parsing: {self.forge_dir}')

        with os.scandir(self.forge_dir) as it:
            for entry in it:
                if entry.is_dir():
                    cate_node = self.__parse_cate(entry)
                    root.children.append(cate_node)
                elif entry.name.endswith('.org'):
                    html_file = re.sub('org$', 'html', entry.name)
                    if not utils.file_exists(html_file):
                        logging.warning(f'missing html file of {entry.name}')
                    page_node = self.__parse_page(entry)
                    root.children.append(page_node)

    def __parse_cate(self, entry):
        node = DocNode(node_type=DocNode.NodeType.CATEGORY)
        return node

    def __parse_page(self, entry):
        node = DocNode(node_type=DocNode.NodeType.PAGE)
        return node
