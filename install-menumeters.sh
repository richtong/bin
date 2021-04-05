#!/usr/bin/env bash
##
## install menumeters for os/x
## http://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install Menumeters taskbar monitoring of system"
		echo "deprecated for yujitach-menumeters"
		echo "flags: -d debug, -v verbose, -h help"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt"
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-mac.sh

set -u
shift $((OPTIND - 1))

if [[ $OSTYPE =~ darwin ]]; then
	brew_install menumeters
	log_exit
	if ! [[ -e /Library/PreferencePanes/MenuMeters.prefPane || -e $HOME/Library/PreferencePanes/MenuMeters.prefPane ]]; then
		curl_and_attach_or_open "http://member.ipmu.jp/yuji.tachikawa/MenuMetersElCapitan/zips/MenuMeters_1.9.5.zip"
	fi
fi
