#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## Install 3D Mapping Software
## @author Rich Tong
## @returns 0 on success
#
# https://github.com/colmap/colmap/releases
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
COLMAP_NAME="${COLMAP_NAME:-COLMAP}"
RELEASE="${RELEASE:-3.7}"
COLMAP_URL="${COLMAP_URL:-"https://github.com/colmap/colmap/releases/download/$RELEASE/$COLMAP_NAME-$RELEASE-mac-no-cuda.zip"}"
COLMAP_BIN="${COLMAP_BIN:-"/Applications/$COLMAP_NAME.app/Contents/MacOS"}"
RC_URL="${RC_URL:-"https://www.capturingreality.com/download"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvfa:r:u:b:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Mapping Software Colmap on Mac, Reality Capture on Windows
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help"
			                       -d $($DEBUGGING && echo "no ")debugging
			                       -v $($VERBOSE && echo "not ")verbose
					   -f force install (default: $FORCE)
					   -a application name (default: $COLMAP_NAME)
			           -r version number (default: $RELEASE)
					   -u download url (default: $COLMAP_URL)
					   -b binary path (default: $COLMAP_BIN)
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
# shellcheck disable=SC1090,SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-install.sh lib-config.sh lib-mac.sh

if in_wsl; then
	log_verbose "Downloading Reality Capture"
	download_url_open "$RC_URL"

elif in_os mac; then

	log_verbose "Downloading $COLMAP_NAME"
	if mac_is_arm; then
		# https://github.com/colmap/colmap/issues/1423
		log_warning "As of February 2023 no M1 version exists so get a side version"
		log_warning "https://mega.nz/file/8wxAnJJK#tcxS3zpb5u7cpJrK0GZ2nhiU4HlBQ6C9cyyEWjJBkxY"
		log_warning "Install the zip into $WS_DIR/cache"

		log_verbose "Install COLMAP prerequisites"
		package_install git cmake boost eigen freeimage glog gflags metis suite-sparse ceres-solver qt5 glew cgal
		if [[ ! -e "$WS_DIR/cache/COLMAP-mac-m1-native-30521f1.zip" ]]; then
			log_error 1 "No M1 version of COLMAP found"
		fi

		if [[ ! -e $WS_DIR/cache/COLMAP.app ]]; then
			unzip "$WS_DIR/cache/COLMAP-mac-m1-native-30521f1.zip"
		fi

	else
		download_url_open "$COLMAP_URL"
	fi

	log_verbose "Move $COLMAP_NAME.app to /Applications"
	COLMAP_DIR="/Applications/$COLMAP_NAME.app"
	if [[ -e $COLMAP_DIR ]] && $FORCE; then
		rm -rf "$COLMAP_DIR"
	fi
	mv "$WS_DIR/cache/$COLMAP_NAME.app" "$(dirname "$COLMAP_DIR")"
	log_verbose "Making CLI available"
	if ! config_mark; then
		config_add <<-EOF
			            echo "\$PATH" | grep -q "$COLMAP_BIN" ]] || PATH="\$PATH:$COLMAP_BIN"
		EOF
	fi
	log_verbose "Download sample images from https://colmap.github.io/datasets.html#datasets"
	log_verbose "Choose Reconstruction/Automatic Reconstruction"
	log_verbose "And pick workspace and image folders"
	log_exit "See https://colmap.github.io/tutorial.html#quick-start"

fi
