# Infrastructure Binary Utility commands

These are (mainly by @richtong) convenience programs for use in installing and
managing the dev environment. They are mainly experimental and are called from here.
There are a few which are used and these are connected to local-bin. See
local-bin/README.md for how to do that

Most of time if you need to install something just try grepping for the right
shell file.

## Finding an installation

The structure here is that `pre-install.sh` is a Bourne shell script that does
the very bases like getting Homebrew. The main way to install is with `install.sh`
with its many flags. Note that it also chains to
`../user/$USER`/bin/user-installsh` for your personal stuff

## Where it fits

This assumes a monorepo that looks like `~/ws/git/src/bin` lives here and there
is parallel `~/ws/git/src/lib` and also personal directories in
`~/ws/git/src/user/$USER`.

## Storing of secrets

The recommendation is to not have any "at rest" secrets. If you must put them on
an encrypted form like ssh-keys. The AWS keys are a real know know.

## Management of environments

There are two levels, `asdf` manages specific versions using `.tool-versions` at
each directory level. This sets the primary versions for everything from node to
python to pipx. It doesn't handle the overall environment though.

If you want to set variables per directory, then you can create a `.envrc` in
each directory and using `source_up` you can make a cascade. It's recommended to
use this to set your various secrets by using `op item get` to retrieve it from
1Password. Or you can use `python layout` which does this automatically

## direnv alternatives

Virtual environments created by poetry, uv or venv or even pipenv (not
recommended), need to have a way to source `/.venv/bin/activate` and then to run
`deactivate` when you are leaving a directory.

While zsh has hooks for entering and leaving a directory, so you can use
[zsh-autoenv](https://github.com/Tarrasch/zsh-autoenv) to do this. It uses
.autoenv.zsh and .autoenv_leave.zsh. So this works mainly with zsh.

Bash is much trickier, instead, you have to alias every
function that changes directories like cd, pushd and popd which is way messier.

One solution is [autoenv](https://github.com/hyperupcall/autoenv) which requires
more .autoenvrc files and .autoenv_leave files to work and it only works for the
common ways like cd. autoenv does this for the common entries. This works by
sourcing its activate.sh for every .bashrc creation.

As a backup, direnv is set so that the default .envrc attempts to do this by
seeing if there is a venv and then source activate which has the deactivate
function in it. This doesn't work if you cd to a non-venv controlled directory
so you get the disturbing result that you keep the last venv on until you get to
a new venv enabled directory.

## mkdocs deploy to github pages

For complete documentation, see the Mkdocs site at the GitHub pages for this
entry, you can regenerated documentation with `mkdocs gh-deploy`

## Building for Netlify (deprecated)

This is all a little complicated, but if you want to make this work, then you
need to make sure that there are three files loaded as
[Niles](https://www.nileshdalvi.com/blog/deploy-static-web-mkdocs-netlify/)
explains:

1. [mkdocs.yml](mkdocs.yml) which has the configuration information for mkdocs
   to build the documentation in [./docs](./docs/)
1. [runtime.txt](runtime.txt). This should have the version number of Python
   that you want to run. (3.11 as of October 2024)
1. [requirements.txt](requirements.txt) which should have the list of packages
   like mkdocs itself that should be pip installed. If you are using
   [uv](https://docs.astral.sh/uv/) then you will need to create a requirements.txt
   file like so
