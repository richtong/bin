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
APP_NAME="${APP_NAME:-COLMAP}"
RELEASE="${RELEASE:-3.6}"
APP_URL="${APP_URL:-"https://github.com/colmap/colmap/releases/download/$RELEASE/$APP_NAME-$RELEASE-mac-no-cuda.zip"}"
APP_BIN="${APP_BIN:-"/Applications/$APP_NAME.app/Contents/MacOS"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvfa:r:u:b:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Mapping Software
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
					   -f force install (default: $FORCE)
					   -a application name (default: $APP_NAME)
			           -r version number (default: $RELEASE)
					   -u download url (defualt: $APP_URL)
					   -b binary path (default: $APP_BIN)
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
		APP_NAME="$OPTARG"
		;;
	r)
		RELEASE="$OPTARG"
		;;
	u)
		APP_URL="$OPTARG"
		;;
	b)
		APP_BIN="$OPTARG"
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

if in_os mac; then
	log_verbose "Downloading $APP_NAME"
	download_url_open "$APP_URL"
	log_verbose "Move $APP_NAME.app to /Applications"
	APP_DIR="/Applications/$APP_NAME.app"
	if [[ -e $APP_DIR ]] && $FORCE; then
		rm -rf "$APP_DIR"
	fi
	mv "$WS_DIR/cache/$APP_NAME.app" "$(dirname "$APP_DIR")"
	log_verbose "Making CLI available"
	if ! config_mark; then
		config_add <<-EOF
			[[ \$PATH =~ $APP_BIN ]] || PATH+=":$APP_BIN"
		EOF
	fi
	log_verbose "Download sample images from https://colmap.github.io/datasets.html#datasets"
	log_verbose "Choose Reconstruction/Automatic Reconstruction"
	log_verbose "And pick workspace and image folders"
	log_exit "See https://colmap.github.io/tutorial.html#quick-start"
fi
