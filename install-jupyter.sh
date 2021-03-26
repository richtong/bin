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

if ! in_os mac; then
	log_exit "Mac only"
fi

brew_install jupyterlab
log_verbose "Installing into the bare environment use pipenv, conda or venv normally"
hash -r

PACKAGES=(
	jupyterlab-lsp
	'python-language-server[all]'
	jupyterlab-system-monitor
	'xeus-python==0.8*'
	'notebook==6*'
	ptvsd
	nodejs
	jupyterlab-git
	nbdime
	aquirdturtle_collapsible_headings
	jupyterlab_vim
)
log_verbose "Installing python extensions ${PACKAGES[*]}"
pip_install "${PACKAGES[@]}"

# this is for node applications but you need to know the node package names
# Latex not up to date
#@jupyterlab/latex
NODE_EXTENSIONS=(
	@jupyterlab/debugger
	@jupyterlab/toc
)
if ((${#NODE_EXTENSIONS[@]} > 0)); then
	log_verbose "Installing Node Extensions ${NODE_EXTENSIONS[*]}"
	jupyter labextension install "${NODE_EXTENSIONS[@]}"
fi
