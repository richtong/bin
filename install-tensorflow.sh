#!/usr/bin/env bash
##
## Install tensorflow
## Smart tensorflow installation works with M1 Mac acceleration
## https://towardsdatascience.com/how-to-install-tensorflow-2-7-on-macbook-pro-m1-pro-with-ease-744bfa978fe8
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
VERSION="${VERSION:-7}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Tensorflow

			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING || echo "no ")debugging
				   -v $($VERBOSE || echo "not ")verbose
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
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-mac.sh

if mac_is_arm; then
	log_verbose "Conda installation is the only way to get tensorflow-deps"

	conda install -c apple tensorflow-deps -y
	pip install tensorflow-macos
	pip install tensorflow-metal1Gjj
elif nvidia; then
	log_verbose "Installing nVidia GPU accelerated tensorflow"
	pip install
	conda install -c conda-forge cudatoolkit=11.2 cudnn=8.10
	export LD_LIBRATY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/
else
	log_verbose "Installing CPU only Tensorflow"
	pip install tensorflow
fi
