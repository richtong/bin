#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## create the .Private secrets for prebuild
##
## Moves secrets into a usb or a Dropbox
##
set -e && SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
ENCRYPTED_DIR=${ENCRYPTED_DIR:-"/media/$USER/.Private"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
DROPBOX_ENCRYPTED=${DROPBOX_ENCRYPTED:-"$HOME/Dropbox/.Private"}
while getopts "hdvurp:e:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: create and copy secrets to new locations"
		echo flags: -d debug -v verbose
		echo "       -u copy to USB key at $ENCRYPTED_DIR (the default)"
		echo "       -r copy to a Dropbox directory at $DROPBOX_ENCRYPTED"
		echo "       -e copy to a specific encrypted directory"
		echo "          or export ENCRYPTED_DIR= before running this script"
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
	u)
		ENCRYPTED_DIR="/media/$USER/.Private"
		;;
	r)
		ENCRYPTED_DIR="$DROPBOX_ENCRYPTED"
		;;
	e)
		ENCRYPTED_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND - 1))

# http://linuxpoison.blogspot.com/2010/10/how-to-use-ecryptfs-cryptographic.html
if ! command -v ecryptfs-setup-private; then
	sudo apt-get install -y ecryptfs-utils
fi

# http://forum.synology.com/enu/viewtopic.php?f=160&t=41568
# http://www.everything-linux-101.com/how-to/encrypt-files-folders/encrypt-folders-with-ecryptfs-on-the-fly/
# http://stackoverflow.com/questions/1473981/how-to-check-if-a-string-has-spaces-in-bash-shell
if [[ "$ENCRYPTED_DIR" != "${ENCRYPTED_DIR%[[:space:]]*}" ]]; then
	log_warning "no white space is allows in the path \"$ENCRYPTED_DIR\""
	exit 1
fi

if [[ ! -d "$ENCRYPTED_DIR" ]]; then
	log_warning "$ENCRYPTED_DIR does not exist or is not a directory, no copy"
	exit 0
fi

log_verbose "found $ENCRYPTED_DIR mount and copy to it"
# We would love to use openssl key pairs, but Ubuntu doesn't ship with this
# http://askubuntu.com/questions/111260/why-cant-i-use-an-openssl-key-pair-with-ecryptfs
# Note this encrypts the filenames which is not the default with the
# ecryptfs-setup-private and it also will prompt you for the passphrase
# it does check the signature cache though, add no_sig_cache if you want to
# defeate that
MOUNTPOINT="$(dirname "$ENCRYPTED_DIR")/Private"
mkdir "$MOUNTPOINT"
mount -t ecryptfs "$ENCRYPTED_DIR" "$MOUNTPOINT" -o \
	key=passphrase,ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_passthrough=n,ecryptfs_enable_filename_crypto=y

log_verbose "mounted $MOUNTPOINT, copying contents to $HOME/Private"
cp -a "$HOME/Private/" "$MOUNTPOINT"
