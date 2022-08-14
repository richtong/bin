#!/usr/bin/env bash
##
## Install TLP laptop power management for ubuntu
## http://www.webupd8.org/2014/10/advanced-power-management-tool-tlp-06.html
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install 1Password"
		echo "flags: -d debug, -h help"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh
set -u
shift $((OPTIND - 1))

if [[ ! $OSTYPE =~ linux ]]; then
	log_error 1 "for linux only"
fi

sudo apt-get purge laptop-mode-tools

apt_repository_install ppa:linrunner/tlp
package_install tlp

log_verbose starting tlp
sudo tlp start
