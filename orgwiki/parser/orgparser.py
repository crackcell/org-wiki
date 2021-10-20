class OrgFile:

    def __init__(self, title=None, author=None, date=''):
        self.title = title
        self.author = author
        self.date = date

    def __str__(self):
        return f'title:{self.title} author:{self.author} date:{self.date}'


def parse_org_file(path):
    org = OrgFile()

    with open(path) as file:
        while True:
            line = file.readline()
            if not line:
                break
            line = line.strip()
            if line.startswith('#+TITLE:') or line.startswith('#+title:'):
                org.title = line[len('#+TITLE:'):].strip()
            elif line.startswith('#+AUTHOR:') or line.startswith('#+author:'):
                org.author = line[len('#+AUTHOR:'):].strip()
            elif line.startswith('#+DATE:') or line.startswith('#+date:'):
                org.date = line[len('#+DATE:'):].strip()

    return org
