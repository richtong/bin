#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install QGround Control
## https://docs.qgroundcontrol.com/master/en/getting_started/download_and_install.html
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:e:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs QGround Control QGC
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
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

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if in_os mac; then

	log_verbose "Download QGroundControl AppImage"
	download_url_open "https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.dmg"

elif in_os linux; then
	log_verbose "Install App Image launcher"
	apt_install software-properties-common
	apt_repository_install ppa:appimagelauncher-team/stable
	apt_install appimagelauncher

	log_verbose "Requires Ubuntu 20.04 or later"
	sudo usermod -a -G dialout "$USER"
	sudo apt-get remove modemmanager -y
	package_install gstreamer1.0-plugins-bad gstreamer1.0-libav gstreamer1.0-gl
	package_install libqt5gui5
	# https://forum.qt.io/topic/116347/fresh-install-5-15-could-not-load-the-qt-platform-plugin-xcb/3
	package_install libxcb-xinerama0
	log_verbose "download AppImage"
	mkdir -p "$HOME/Applications"
	download_url "https://d176tv9ibo4jno.cloudfront.net/latest/QGroundControl.AppImage" QGroundControl.AppImage "$HOME/Applications"
	chmod +x "$HOME/Applications/QGroundControl.AppImage"

fi
