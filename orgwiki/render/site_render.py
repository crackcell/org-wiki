from jinja2 import Environment, FileSystemLoader
from orgwiki.parser.forge_parser import DocTreeNodeType


def render(tree, config):
    template_dir = f'{config["template_dir"]}/{config["template_name"]}'
    env = Environment(loader=FileSystemLoader(template_dir))

    tree_html = __render_tree(tree, env, config)
    __write_file(f'{config["site_dir"]}/tree.html', tree_html)


def __render_tree(tree, env, config):
    tree_snippet = __render_tree_snippet(tree)
    tree_tmpl = env.get_template('tree.html')
    return tree_tmpl.render(site_name=config['site_name'], tree_html=tree_snippet)


def __render_tree_snippet(node, indent=1):
    indent_str = '    ' * indent
    href = node.path
    if href.startswith('./'):
        href = href.removeprefix('./')

    snippet = ''

    if node.node_type == DocTreeNodeType.ROOT or node.node_type == DocTreeNodeType.CATEGORY:

        if node.node_type == DocTreeNodeType.CATEGORY:
            expand = 'false' if node.fold else 'true'
            snippet = \
                f'{indent_str}<li item-checked="true" item-expanded="{expand}"><a href="{href}/" target="content"><b>{node.label}</b></a>\n' + \
                f'{indent_str}<ul>\n'

        page_children = []
        cate_children = []
        for child in node.children:
            if child.node_type == DocTreeNodeType.PAGE:
                page_children.append(child)
            elif child.node_type == DocTreeNodeType.CATEGORY:
                cate_children.append(child)
            else:
                raise Exception(f'invalid node type {child.node_type}')

        for child in page_children:
            snippet += __render_tree_snippet(child, indent + 1)
        for child in cate_children:
            snippet += __render_tree_snippet(child, indent + 1)

        snippet += f'{indent_str}</ul>\n'

        return snippet

    elif node.node_type == DocTreeNodeType.PAGE:
        snippet = f'{indent_str}<li><a href="{href}" target="content">{node.label}</a></li>\n'

    else:
        raise Exception(f'invalid node type {node.node_type}')

    return snippet


def __write_file(path, content):
    with open(path, 'w') as file:
        file.write(content)
