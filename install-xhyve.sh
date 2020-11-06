#!/usr/bin/env bash
##
## Install docker machine [xhyve driver]
## (https://github.com/kubernetes/minikube/blob/master/DRIVERS.md#xhyve-driver)
## https://www.wavether.com/2016/09/docker-machine-xhyve-mac-os
## Needed for minikubes no longer needed for docker for mac
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install xhyve for Mac to use with docker"
		echo "flags: -d debug, -h help -v verbose"
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

if [[ ! $OSTYPE =~ darwin ]]; then
	log_warning Only for Macs
	exit 0
fi
XHYVE=${XHYVE:-"docker-machine-driver-xhyve"}
XHYVE_BIN=${XHYVE_BIN:-"$(brew --prefix)/opt/$XHYVE/bin/$XHYVE"}

log_verbose install xhyve
brew_install xhyve
if brew_install "$XHYVE" | grep -q "requires superuser privileges"; then
	log_verbose error usual because it needs to setuid
	sudo chown root:wheel "$XHYVE_BIN"
	sudo chmod u+s "$XHYVE_BIN"
fi
