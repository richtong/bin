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
			Installs Jupyter and other good parts
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

PACKAGES=(
	'notebook>=6'
	'jupyterlab>=3'
	'jupyterhub>=1.4'
	nodejs
	jupyterlab-git
	jupyterlab-github
	aquirdturtle_collapsible_headings
	jupyterlab-system-monitor
	nbdime
	jupyterlab_vim
	jupyterlab-lsp
	'python-language-server[all]'
	black
	yapf
	isort
)
log_verbose "Installing python extensions ${PACKAGES[*]}"
pip_install "${PACKAGES[@]}"

INTEL=(
	'xeus-python>=0.8.6'
	nb-mermaid
	jupyterlab_hdf
	hdf5plugin
)

if mac_is_arm; then
	log_verbose "Mac Intel only versions installed"
	pip_install "${INTEL[@]}"
fi

# this is for node applications but you need to know the node package names
# Latex not up to date
#@jupyterlab/latex
# included by default
#@jupyterlab/debugger
NODE_EXTENSIONS=(
	@jupyterlab/toc
)
if ((${#NODE_EXTENSIONS[@]} > 0)); then
	log_verbose "Installing Node Extensions ${NODE_EXTENSIONS[*]}"
	jupyter labextension install "${NODE_EXTENSIONS[@]}"
fi

# https://github.com/jupyter/nbconvert
# for nbconvert
# http://tug.org/mactex/
# this library is huge takes 5GB so do not install typically
#package_install mactex

log_verbose "Add to the path"
eval "$(/usr/libexec/path_helper)"
