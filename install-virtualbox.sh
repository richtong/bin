#!/usr/bin/env bash
##
## install virtualbox
## https://tecadmin.net/install-oracle-virtualbox-on-ubuntu/
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
RELEASE="${RELEASE:-5.1}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		echo Install Virtualbox
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -r Virtualbox release (default: $RELEASE)"
		echo
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	r)
		RELEASE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh
shift $((OPTIND - 1))

if [[ $OSTYPE =~ darwin ]]; then
	# https://gist.github.com/tbonesteaks/000dc2d0584f30013913
	cask_install virtualbox
	cask_install virtualbox-extension-pack
	log_exit virtual box installed with brew
fi

log_verbose get public keys
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

log_verbose add vbox repo
repository_install "deb http://download.virtualbox.org/virtualbox/debian $(linux_codename) contrib"

log_verbose "install virtualbox $RELEASE"

# dkms needed to auto updates virtualbox kernel modules
# https://www.virtualbox.org/wiki/Linux_Downloads
package_install dkms "virtualbox-$RELEASE"
