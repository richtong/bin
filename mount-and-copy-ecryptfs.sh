#!/usr/bin/env bash
##
## Mount ~/Private and Then mount
## then copy Dropbox/Private to the per-user private
## Works for Ubuntu and Debian
##
#
set -e && SCRIPTNAME="$(basename $0)"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1

# Note the shared mountpoint cannot be in the $DROPBOX directory or it will sync in the clear
# to other machines
DROPBOX="${DROPBOX:-"Dropbox"}"
PRIVATE_MOUNTPOINT="${PRIVATE_MOUNTPOINT:-"$HOME/Private"}"
SHARED_ENCRYPTED_DIR="${SHARED_ENCRYPTED_DIR:-"$HOME/$DROPBOX/Private"}"
SHARED_MOUNTPOINT="${SHARED_MOUNTPOINT:-"$HOME/$DROPBOX-Private"}"
while getopts "hdvp:s:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Setup ecryptfs in a private mountpoint using data from Dropbox
   usage: $SCRIPTNAME [flags]
   flags: -d debug -v verbose"
          -p Encrypted mountpoint for regular use (default: $PRIVATE_MOUNTPOINT)
          s Encrypted mountpoint that has shared keys (default: $SHARED_MOUNTPOINT)"
          Note that if mountpoint not found it will look for it in ~/Dropbox, ~/Dropbox (Personal
          and then see if there is a corporate one.
          If the dmg does not exist it will suggest creating one and copy the current
          contents of ~/.ssh into $PRIVATE_MOUNTPOINT
EOF
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        p)
            PRIVATE_MOUNTPOINT="$OPTARG"
            ;;
        s)
            SHARED_MOUNTPOINT="$OPTARG"
            ;;
    esac
done

if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u
shift $((OPTIND-1))

if [[ ! $OSTYPE =~ linux ]]
then
    log_error 1 "Only available on Linux not $OSTYPE"
    exit 1
fi

# http://linuxpoison.blogspot.com/2010/10/how-to-use-ecryptfs-cryptographic.html
package_install ecryptfs-utils

if in_linux debian
then
    # https://wiki.debian.org/TransparentEncryptionForHomeFolder#Transparent_Encryption_For_the_User.27s_Home_Folder
    log_verbose add ecryptfs now and make it permanent in mod probe
    mod_install ecryptfs
fi

if [[ ! -e  $PRIVATE_MOUNTPOINT ]]
then
    log_verbose "setup $PRIVATE_MOUNTPOINT"
    ecryptfs-setup-private
    ecryptfs-mount-private
fi

# Note in debian swapon requires sudo
log_verbose see if we a do not have an encrypted swapfile
    if (( $(sudo swapon -s | wc -l) > 1 )) && ! sudo swapon -s | grep cryptswap
    then
        log_verbose "encrypt the swap file"
        if in_linux ubuntu
        then
            log_verbose does not appear to work in 14 or 16 do not know about ubuntu 15 or 17
                case $(linux_version) in
                    ^14*)
                        log_warning "encrypt swap file hangs on ubuntu 14.04 skipping"
                        ;;
                    ^16*)
                        log_warning "encrypt-setup-swap says cryptswap no found no swap created"
                        ;;
                esac
        elif in_linux debian
            then
                log_warning cryptsetup needed for Debian
                package_install cryptsetup
                log_warning "ecrypt setup swap fails on Debian 9 do not install"
            else
                sudo ecryptfs-setup-swap
            fi
        fi

        log_verbose make sure $SHARED_MOUNTPOINT exists

        if [[ ! -e "$(dirname "$SHARED_MOUNTPOINT")" ]]
        then
            log_verbose "$SHARED_MOUNTPOINT does not exist search other locations"
            target="$(basename "$SHARED_MOUNTPOINT")"
            for dropbox in "$SCRIPT_DIR/find-dropbox.sh"
            do
                dir="$dropbox/$target"
                if [[ -e "$dir" ]]
                then
                    log_verbose could not find "$SHARED_MOUNTPOINT" but found "$dir" replacing
                    SHARED_MOUNTPOINT="$dir"
                    break
                fi
                log_verbose $dir not found
            done
            log_error 2 "No $dir found in any Dropbox folders did you sync yet? or create a $target with make-private.sh"
        fi

        log_verbose $PRIVATE_MOUNTPOINT is up so now mount $SHARED_MOUNTPOINT
        "$SCRIPT_DIR/mount-ecryptfs.sh" "$SHARED_MOUNTPOINT"

        log_verbose look for ssh on $SHARED_MOUNTPOINT
        if [[ ! -e "$SHARED_MOUNTPOINT/ssh" ]]
        then
            log_error 2 "no files in $SHARED_MOUNTPOINT did you run Dropbox sync"
        fi

        # We copy because Private is automounted and we do not need Dropbox all the time
        log_verbose only copy $USER directories
        cp -a "$SHARED_MOUNTPOINT/"* "$PRIVATE_MOUNTPOINT"

        log_verbose make sure our permissions are closed
        "$SCRIPT_DIR/fix-ssh-permissions.sh" "$PRIVATE_MOUNTPOINT/ssh"
