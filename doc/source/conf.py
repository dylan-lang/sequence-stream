# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Sequence Stream'
copyright = '2026, Dustin Voss'
author = 'Dustin Voss'
release = '0.1.0'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

import sys, os
sys.path.insert(0, os.path.abspath('../../_packages/sphinx-extensions/current/src/sphinxcontrib'))

import dylan.themes as dylan_themes

extensions = [
    'dylan.domain',
    'sphinx_copybutton'
]

primary_domain = 'dylan'
templates_path = ['_templates']
exclude_patterns = []

# -- Options for copybutton -------------------------------------------------
# https://sphinx-copybutton.readthedocs.io/en/latest/use.html

# Skip line numbers and prompt characters
copybutton_exclude = '.linenos, .gp'

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'furo'
html_static_path = ['_static']

html_theme_options = {
    'source_repository': 'https://github.com/dylan-lang/sequence-stream',
    'source_branch': 'master',
    'source_directory': 'doc/source',
}
