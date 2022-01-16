#!/usr/bin/env bash
##
## Install Jupyter
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Jupyter and other good parts in a bare metal installation
			You should really run this in pipenv or a container
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $VERSION)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh
log_verbose "You can also install as a docker container from tongfamily/jupyterlab"

if ! in_os mac; then
	log_exit "Mac only"
fi

brew_install jupyterlab
log_verbose "Installing into the bare environment use pipenv, conda or venv normally"
hash -r

# nbdime - Notebook diff and merge cli and jupyterlab command line interface
PIP_PACKAGE=(
	notebook
	jupyterlab
	jupyterhub
	nodejs
	jupyterlab-git
	jupyterlab-github
	aquirdturtle_collapsible_headings
	jupyterlab-system-monitor
	nbdime
	jupyterlab_vim
	'python-language-server[all]'
	black
	yapf
	isort
	jupyterlab-hide-code
	jupyterlab-spellchecker
	"python-lsp-server[all]"
	ipywidgets
	jupyterlab_widgets
	jupyter_bokeh
	jupyter-dash
	pillow
	graphviz
	blockdiagmagic
	"ipydrawio[all]"
	ipydrawio-export
	nb-js-diagrammers
	pivottablejs
	jupyterlab_code_formatter
	black
	isort
	yapf
	jupytext
)
log_verbose "Installing python extensions ${PIP_PACKAGE[*]}"
pip_install "${PIP_PACKAGE[@]}"

INTEL_PACKAGE=(
	'xeus-python>=0.8.6'
	nb-mermaid
	jupyterlab_hdf
	hdf5plugin
)

if mac_is_arm; then
	log_verbose "Mac Intel only versions installed"
	pip_install "${INTEL_PACKAGE[@]}"
fi

# https://github.com/jupyter/nbconvert
# for nbconvert
# http://tug.org/mactex/
# this library is huge takes 5GB so do not install typically
log_verbose "Run mermaid to generate JPGs from .mermaid files"
log_verbose "Wanring mactex is huge at 5GB so only install if needed for pdfs"
PACKAGE=(
	mermaid-cli
	pandoc
	mactex
)

package_install "${PACKAGE[@]}"

# this is for node applications but you need to know the node package names
# Latex not up to date
#@jupyterlab/latex
# included by default
#@jupyterlab/debugger
# toc now included in Jupterlab 3.0
#NODE_EXTENSIONS=(
#    @jupyterlab/toc
#)
#if ((${#NODE_EXTENSIONS[@]} > 0)); then
#    log_verbose "Installing Node Extensions ${NODE_EXTENSIONS[*]}"
#    jupyter labextension install "${NODE_EXTENSIONS[@]}"
#fi

# https://nbdime.readthedocs.io/en/latest/extensions.html
log_verbose "Enable git to use nbdime to diff notebooks"
nbdime config-git --enable --global
# nbdime extenstions enabled at install
#nddime extensions --enable

log_verbose "Add to the path"
eval "$(/usr/libexec/path_helper)"

if [[ ! -e $HOME/.jupyter/nbconfig.json ]]; then
	# https://stackoverflow.com/questions/36419342/how-to-wrap-code-text-in-jupyter-notebooks
	log_verbose "Adding word wrap to cells"
	cat >"$HOME/.jupyter/nbconfig.json" <<-"EOF"
		{
		  "Cell": {
			"cm_config": {
			  "lineNumbers": false,
			  "lineWrapping": true
			}
		  }
		}
	EOF
fi

# https://nbdime.readthedocs.io/en/latest/vcs.html#git-integration
log_verbose "enable for Jupyter Notebooks in github $HOME/.gitconfig"
nbdime config-git --enable --global

# https://github.com/mwouts/jupytext
log_verbose "use percent format for mainly code with # %% delimiters"
log_verbose "   jupytertext --to py:percent notebook.ipynb"
log_verbose "use markdown for rendering on GitHub as a README.md without outputs"
log_verbose "   jupytext --to markdown notebook.ipynb"
log_verbose "use MyST for rendering to Sphinx or Jupyter Book"
log_verbose "   jupytext --to md:myst, notebook.ipynb"
log_verbose "sync from the last modified .ipynb or .md to the other"
log_verbose "   jupytext -s notebook.ipynb"
