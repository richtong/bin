#!/usr/bin/env bash
##
## Install 3D Mapping Software
## https://github.com/colmap/colmap/releases
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
RELEASE="${RELEASE:-3.6}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Mapping Software
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $RELEASE)
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
	r)
		RELEASE="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if in_os mac; then
	log_verbose "Downloading Colmap"
	download_url_open \
		"https://github.com/colmap/colmap/releases/download/$RELEASE/COLMAP-$RELEASE-mac-no-cuda.zip"
	log_verbose "Move .app to /Applications"
	mv "$WS_DIR/cache/COLMAP.app" "/Applications"
	log_verbose "Download sample images from https://colmap.github.io/datasets.html#datasets"
	log_verbose "Choose Reconstruction/Automatic Reconstruction"
	log_verbose "And pick workspace and image folders"
	log_exit "See https://colmap.github.io/tutorial.html#quick-start"
fi
