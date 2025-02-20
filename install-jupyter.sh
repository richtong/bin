#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install Jupyter
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
# this replace set -e by running exit on any error use for bashdb
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Jupyter and other good parts in a bare metal installation
			You should really run this in pipenv or a container
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help"
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
			           -r version number (default: $VERSION)
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		export VERBOSE=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-mac.sh lib-config.sh
log_verbose "You can also install as a docker container from tongfamily/jupyterlab"

if ! in_os mac; then
	log_exit "Mac only"
fi

pipx install jupyterlab
# ipython is installed but needs to be linked
# key link no longer needed
#log_verbose "brew keg link jupyterlab and ipython"
#brew link ipython jupyterlab
log_verbose "Installing into the bare environment use pipenv, conda or venv normally"
hash -r

# nbdime - Notebook diff and merge cli and jupyterlab command line interface
PIP_PACKAGE=(

	aquirdturtle_collapsible_headings
	black
	blockdiagmagic
	graphviz
	"ipydrawio[all]"
	ipydrawio-export
	ipywidgets
	isort
	jupyter-dash
	jupyter_bokeh
	jupyterhub
	jupyterlab
	jupyterlab-git
	jupyterlab-github
	jupyterlab-hide-code
	jupyterlab-spellchecker
	jupyterlab-system-monitor
	jupyterlab_code_formatter
	jupyterlab_vim
	jupyterlab_widgets
	jupytext
	nb-js-diagrammers
	nbdime
	nodejs
	notebook
	pillow
	pivottablejs
	"python-lsp-server[all]"
	'python-language-server[all]'
	yapf

)
log_verbose "Installing python extensions ${PIP_PACKAGE[*]}"
pipx inject jupyterlab "${PIP_PACKAGE[@]}"

INTEL_PACKAGE=(
	'xeus-python>=0.8.6'
	nb-mermaid
	jupyterlab_hdf
	hdf5plugin
)

if ! mac_is_arm; then
	log_verbose "Mac Intel only versions installed"
	pipx inject jupyterlab "${INTEL_PACKAGE[@]}"
fi

# https://github.com/jupyter/nbconvert
# for nbconvert
# http://tug.org/mactex/
# this library is huge takes 5GB so do not install typically
# https://pandoc.org/installing.html
# mermaid-cli - install chromium in the background so beware
log_verbose "Run mermaid to generate JPGs from .mermaid files"
PACKAGE=(
	mermaid-cli
	pandoc
)

package_install "${PACKAGE[@]}"

log_verbose "Warning mactex is huge at 5GB so only basictex and load modules as"
log_verbose "needed install if needed for pdfs"
"$BIN_DIR/install-latex.sh"

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

if [[ ! -e $HOME/.jupyter/nbconfig.json ]]; then
	# https://stackoverflow.com/questions/36419342/how-to-wrap-code-text-in-jupyter-notebooks
	log_verbose "Adding word wrap to cells"
	mkdir -p "$HOME/.jupyter"
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
