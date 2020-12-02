#!/usr/bin/env bash
##
## Install file system access over ssh
## With fuse licensing changes, homebrew no longer supports it so this is
## deprecated. See https://github.com/Homebrew/homebrew-core/pull/64491
##
## This tunnels your file system access over ssh so you do not need kerberos
## and can protect file system access by NFS easily. The client just needs ssh
## access to the host
## https://www.digitalocean.com/community/tutorials/how-to-use-sshfs-to-mount-remote-file-systems-over-ssh
##
## Compared with NFS over a WAN, this is a nice option as you only need ssh
## access. But https://forums.opensuse.org/showthread.php/414755-sshfs-vs-nfs
## notes that there are performance penalties, so internally best to use NFS v4
## which has encryption but then you need to install Kerberos (yuck!)
##
## Biggest drawback to sshfs is lack of file locking
## https://unix.stackexchange.com/questions/14014/can-someone-sniff-nfs-over-internet
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
		echo Install SSHFS for file system access over ssh
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
source_lib lib-install.sh lib-mac.sh

shift $((OPTIND - 1))

if [[ $OSTYPE =~ darwin ]]; then
	# http://brewformulas.org/Sshfs
	# might be inaccurate but apparently sshfs might require some kext hacking
	# https://writing.pupius.co.uk/mount-a-remote-filesystem-with-sshfs-8a37e85b39ee
	cask_install osxfuse
fi
package_install sshfs

log_assert "command -v sshfs >/dev/null" "sshfs installed"
