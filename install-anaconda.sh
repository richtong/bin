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
MINICONDA="${MINICONDA:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Anaconda
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -f install miniconda and not full (default: $MINICONDA)
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
	f)
		MINICONDA=true
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

if ! $MINICONDA; then
	cask_install anaconda
	# https://github.com/Homebrew/homebrew-cask/issues/66490
	if ! config_mark; then
		# shellcheck disable=SC2016
		config_add <<<'[[ $PATH =~ /usr/local/anaconda3/bin ]] || export PATH="/usr/local/anaconda3/bin:$PATH'
	fi
else
	cask_install miniconda
fi

# return true in case there are errors in the source
source_profile
conda init "$(basename "$SHELL")"
source_profile
log_verbose take all the updates

# https://github.com/conda/conda/issues/9589
# Need this for a bug in 4.8.3
log_verbose get latest anaconda
conda update conda

log_verbose to use Anaconda make sure to source your profile
