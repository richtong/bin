#!/usr/bin/env bash
##
## install ecryptfs
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
PRIVATE_MOUNTPOINT="${PRIVATE_MOUNTPOINT:-"$HOME/Private"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo Install ecryptfs
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
source_lib lib-install.sh lib-util.sh
shift $((OPTIND - 1))

if ! in_os linux; then
	log_exit linux only
	## https://www.npmjs.com/package/onepass-cli for npm package
fi

# http://linuxpoison.blogspot.com/2010/10/how-to-use-ecryptfs-cryptographic.html
package_install ecryptfs-utils
if in_linux debian; then
	# https://wiki.debian.org/TransparentEncryptionForHomeFolder#Transparent_Encryption_For_the_User.27s_Home_Folder
	log_verbose add ecryptfs now and make it permanent in mod probe
	mod_install ecryptfs
fi

if [[ ! -e $PRIVATE_MOUNTPOINT ]]; then
	log_verbose "setup $PRIVATE_MOUNTPOINT"
	log_verbose "when called from a script this does not produce output"
	ecryptfs-setup-private
	log_verbose "mount private"
	ecryptfs-mount-private
fi

# Note in debian swapon requires sudo
log_verbose "see if we a do not have an encrypted swapfile"
if (($(sudo swapon -s | wc -l) > 1)) && ! sudo swapon -s | grep cryptswap; then
	log_verbose "encrypt the swap file"
	if in_linux ubuntu; then
		log_verbose "does not appear to work in 14 or 16 do not know about ubuntu 15 or 17"
		case $(linux_version) in
		^14*)
			log_warning "encrypt swap file hangs on ubuntu 14.04 skipping"
			;;
		^16*)
			log_warning "encrypt-setup-swap says cryptswap no found no swap created"
			;;
		esac
	elif in_linux debian; then
		log_warning cryptsetup needed for Debian
		package_install cryptsetup
		log_warning "ecrypt setup swap fails on Debian 9 do not install"
	else
		sudo ecryptfs-setup-swap
	fi
	exit
fi
