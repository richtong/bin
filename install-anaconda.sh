#!/usr/bin/env bash
##
## install Anaconda for Mac only
## https://medium.com/ayuth/install-anaconda-on-macos-with-homebrew-c94437d63a37
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
FULLCONDA="${FULLCONDA:-false}"
NOFORGE="${NOFORGE:-false}"
PYTHON="${PYTHON:-3.8}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvacf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Miniconda (you can install anaconda but more dependency issues)
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -a install miniconda and not full (default: $FULLCONDA)
					   -c do not install conda-forge (defualt: NOFORGE)
					   -p install python version (default: $PYTHON)
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
	c)
		NOFORGE=true
		;;
	f)
		FULLCONDA=true
		;;
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

if ! in_os mac; then
	log_exit "mac only"
fi

if $FULLCONDA; then
	cask_install anaconda
else
	cask_install miniconda
fi

if ! $NOFORGE; then
	conda config --env --add channels conda-forge
	conda config --env --set channel_priority strict
fi

# return true in case there are errors in the source
source_profile
conda init "$(basename "$SHELL")"
source_profile
log_verbose take all the updates

# https://github.com/conda/conda/issues/9589
# Need this for a bug in 4.8.3
log_verbose get latest anaconda and packages
conda update conda --all -y
conda install "python=$PYTHON"

log_warning "you should not install into base create your own environment"
