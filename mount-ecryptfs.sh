#!/usr/bin/env bash
##
## Mount ecryptfs into a given mount point
## The default is to mount ~/Dropbox/.Private to ~/Dropbox/Private
##
#
set -e && SCRIPTNAME="$(basename $0)"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
echo $HOME
SYNC="${SYNC:-Dropbox}"
PRIVATE="${NAME:-Private}"
ENCRYPTED_DIR="${ENCRYPTED_DIR:-"$HOME/$SYNC/.$PRIVATE"}"
# Mount point cannot be in Dropbox because it will replicate unencyrpted
MOUNTPOINT="${MOUNTPOINT:-"$HOME/$SYNC.$PRIVATE"}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: install encryption for ~/Private and others
            echo flags: -d debug -v verbose
            echo "positional parameters:"
            echo "       mount point (default is $MOUNTPOINT)"
            echo "       optional encrypted directory (default is $ENCRYPTED_DIR)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done

if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

set -u
shift $((OPTIND-1))
MOUNTPOINT=${1:-"$MOUNTPOINT"}
ENCRYPTED_DIR=${2:-"$ENCRYPTED_DIR"}

if mount | grep -q "$MOUNTPOINT"
then
    log_warning $MOUNTPOINT already exists
fi

log_verbose mount $ENCRYPTED_DIR to $MOUNTPOINT
# http://forum.synology.com/enu/viewtopic.php?f=160&t=41568
# http://www.everything-linux-101.com/how-to/encrypt-files-folders/encrypt-folders-with-ecryptfs-on-the-fly/
# http://stackoverflow.com/questions/1473981/how-to-check-if-a-string-has-spaces-in-bash-shell
if [[ "$ENCRYPTED_DIR" != "${ENCRYPTED_DIR%[[:space:]]*}" ]]
then
    log_warning no white space is allowed in path \"$ENCRYPTED_DIR\"
    exit 1
fi

if [[ $(df  -T | grep ecryptfs | awk '{print $7}') =~ "$ENCRYPTED_DIR" ]]
then
    log_warning $ENCRYPTED_DIR is already mounted
    exit 0
fi

# We would love to use openssl key pairs, but Ubuntu doesn't ship with this
# http://askubuntu.com/questions/111260/why-cant-i-use-an-openssl-key-pair-with-ecryptfs
# Note this encrypts the filenames which is not the default with the
# ecryptfs-setup-private and it also will prompt you for the passphrase
# it does check the signature cache though, add no_sig_cache if you want to
# defeate that. Uses AES-256 encrpytion (32 bytes)
mkdir -p "$MOUNTPOINT"
mkdir -p "$ENCRYPTED_DIR"
package_install ecryptfs-utils

log_verbose checking to see if "$MOUNTPOINT" already there
# https://serverfault.com/questions/143084/how-can-i-check-whether-a-volume-is-mounted-where-it-is-supposed-to-be-using-pyt
if ! grep "$MOUNTPOINT" /proc/mounts
then
    log_message This is *not* your login passphrase, it is the passphrase for the encrypted Dropbox/.Private partition!
    log_message if you are @rich ecryptfs hash is 62ad457cfc05a100 shows you got the correct one
    log_message for others, please let @rich know and he will add to the public-keys repo
    log_message if this is *not* the correct hash, CTRL-C to exit or if you make a mistake then umount $MOUNTPOINT

        # no-sig-cache means it doesn't check the passphrase
        sudo mount -t ecryptfs "$ENCRYPTED_DIR"  "$MOUNTPOINT" -o \
            "key=passphrase,ecryptfs_cipher=aes,ecryptfs_key_bytes=32,ecryptfs_passthrough=n,ecryptfs_enable_filename_crypto=y"
    fi

    log_verbose mounted $ENCRYPTED_DIR to $MOUNTPOINT so you can copy secrets into $MOUNTPOINT
