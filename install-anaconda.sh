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
NOFORGE="${NOFORGE:-false}"
PYTHON="${PYTHON:-3.9}"
ANACONDA="${ANACONDA:-miniconda}"
URL="${URL:-https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh}"
VERSION="${VERSION:-2020.11}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvacfp:r:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Miniconda (you can install anaconda but more dependency issues)
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -a install full Anaconda (default: not $ANACONDA)
					   -c do not install conda-forge (defualt: $NOFORGE)
					   -p install python version (default: $PYTHON)
					   -r install anaconda version (default: $VERSION)
					   -u install miniconda version from (default: $URL)
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
		ANACONDA=anaconda
		URL="https://repo.anaconda.com/archive/Anaconda3-$VERSION-Linux-x86_64.sh"
		;;
	p)
		PYTHON="$OPTARG"
		;;
	r)
		VERSION="$OPTARG"
		;;
	u)
		URL="$OPTARG"
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

if in_os mac; then
	cask_install "$ANACONDA"
elif ! command -v conda &>/dev/null; then
	log_verbose "downloading $URL and running it"
	# https://docs.continuum.io/anaconda/install/linux/
	download_url "$URL"
	log_verbose "run script"
	bash "$WS_DIR/cache/$(basename "$URL")"
fi

source_profile

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
conda deactivate
log_debug "do not conda on by default"
if ! config_mark; then
	config_add <<<"conda deactivatK"
fi
