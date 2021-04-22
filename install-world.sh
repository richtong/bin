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
COLMAP_NAME="${COLMAP_NAME:-COLMAP}"
RELEASE="${RELEASE:-3.6}"
COLMAP_URL="${COLMAP_URL:-"https://github.com/colmap/colmap/releases/download/$RELEASE/$COLMAP_NAME-$RELEASE-mac-no-cuda.zip"}"
COLMAP_BIN="${COLMAP_BIN:-"/Applications/$COLMAP_NAME.app/Contents/MacOS"}"
RC_URL="${RC_URL:-"https://www.capturingreality.com/download"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvfa:r:u:b:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Mapping Software Colmap, Reality Capture, Unreal Engine
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f force install (default: $FORCE)
					   -a application name (default: $COLMAP_NAME)
			           -r version number (default: $RELEASE)
					   -u download url (defualt: $COLMAP_URL)
					   -b binary path (default: $COLMAP_BIN)
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
		FORCE=true
		;;
	a)
		COLMAP_NAME="$OPTARG"
		;;
	r)
		RELEASE="$OPTARG"
		;;
	u)
		COLMAP_URL="$OPTARG"
		;;
	b)
		COLMAP_BIN="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-install.sh lib-config.sh

if in_wsl; then
	log_verbose "Downloading Reality Capture"
	download_url_open "$RC_URL"
fi

log_verbose "Downloading $COLMAP_NAME"
download_url_open "$COLMAP_URL"
log_verbose "Move $COLMAP_NAME.app to /Applications"
COLMAP_DIR="/Applications/$COLMAP_NAME.app"
if [[ -e $COLMAP_DIR ]] && $FORCE; then
	rm -rf "$COLMAP_DIR"
fi
mv "$WS_DIR/cache/$COLMAP_NAME.app" "$(dirname "$COLMAP_DIR")"
log_verbose "Making CLI available"
if ! config_mark; then
	config_add <<-EOF
		[[ \$PATH =~ $COLMAP_BIN ]] || PATH+=":$COLMAP_BIN"
	EOF
fi
log_verbose "Download sample images from https://colmap.github.io/datasets.html#datasets"
log_verbose "Choose Reconstruction/Automatic Reconstruction"
log_verbose "And pick workspace and image folders"
log_exit "See https://colmap.github.io/tutorial.html#quick-start"
