#!/usr/bin/env bash
##
## Install and mount HFS+ drives from the mac
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install 1Password
            echo "flags: -d debug, -h help"
            echo "/dev/sd disk to mount will mount to /media/sdx"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u
shift $((OPTIND-1))

# pulls things assuming your git directory is $WS_DIR/git a la Sam's convention
# There is an optional 2nd parameter for the repo defaults to your organization

if in_os mac
then
    log_error 1 do not need on a Mac
    fi

    package_install hfsprogs

    if (( $# < 1 ))
    then
        log_warning need a disk to mount from
        echo $(disks_list_possible)
        exit 2
    fi

    log_verbose file check the disk first
    sudo fsck.hfsplus "$DISK"
    # https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
    for disk in "$@"
    do
        if [[ ! -e $disk ]]
        then
            log_warning no disk $disk found
        fi
        name=$(basename disk)
        sudo mount -t hfsplus -o remount,force,rw /dev/$disk /media/$name
        log_message mounted /dev/$disk to /media/$name
    done
