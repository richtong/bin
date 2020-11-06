#!/usr/bin/env bash
##
## install Firewall ufw and enable ssh access
##
## https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nfs-mount-on-ubuntu-16-04
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo Install UFW Firewall
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo
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
shift $((OPTIND - 1))
source_lib lib-install.sh

if [[ ! $OSTYPE =~ linux ]]; then
	log_exit "Only for linux"
fi

package_install ufw

log_verbose checking if ufw enabled
if ! sudo ufw status | grep -q "Status: active"; then
	log_verbose ufw enabled and OpenSSH allowed
	sudo ufw enable
	sudo ufw allow OpenSSH
fi

log_assert 'sudo ufw status | grep -q "Status: active"' "UFW active"
log_assert 'sudo ufw status | grep -q "OpenSSH"' "OpenSSH alloed by UFW"
