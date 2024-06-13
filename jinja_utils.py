import os

from jinja2 import Environment, FileSystemLoader
from token_utils import get_token, decrypt_token

def get_template(dir_path, template_file):
    """
    Initializes jinja env and return template
    """
    environment = Environment(loader=FileSystemLoader(dir_path))
    return environment.get_template(template_file)