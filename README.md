# Infrastructure Binary Utility commands

These are (mainly by @richtong) convenience programs for use in installing and
managing the dev environment. They are mainly experimental and are called from here.
There are a few which are used and these are connected to local-bin. See
local-bin/README.md for how to do that

Most of time if you need to install something just try grepping for the right
shell file.

For complete documentation, see the Mkdocs site at the GitHub pages for this
entry, you can regenerated documentation with `mkdocs gh-deploy`

## Building for Netlify (deprecated)

This is all a little complicated, but if you want to make this work, then you
need to make sure that there are three files loaded as [Niles](https://www.nileshdalvi.com/blog/deploy-static-web-mkdocs-netlify/)
explains:

1. [mkdocs.yml](mkdocs.yml) which has the configuration information for mkdocs
   to build the documentation in [./docs](./docs/)
1. [runtime.txt](runtime.txt). This should have the version number of Python
   that you want to run. (3.11 as of October 2024)
1. [requirements.txt](requirements.txt) which should have the list of packages
   like mkdocs itself that should be pip installed. If you are using
   [uv](https://docs.astral.sh/uv/) then you will need to create a requirements.txt
   file like so
