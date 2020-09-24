#!/usr/bin/env bash
##
## https://help.ubuntu.com/14.04/serverguide/network-file-system.html
##
## Note this does not work on the mac as NFS is already loaded
## Also we do not want persistent mounts on Mac
## If you do see https://gist.github.com/lawrencealan/8697518
## and edit your /etc/auto_master file not /etc/fstab
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

SERVER=${SERVER:-"ai0.local"}
POOLS=${POOLS:-"zfs"}
SHARES=${SHARES:-"data home"}
OPTIND=1
while getopts "hdvs:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install nfs client
            echo "flags: -d debug, -h help"
            echo "       -s server (default: $SERVER)"
            echo "positionals: pool names (default: $POOLS)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        s)
            SERVER="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

shift $((OPTIND-1))
POOLS=${1:-$POOLS}
set -u

if 1 in_os linux
then
    log_warning only runs on linux
    exit
fi

package_install nfs-common

log_verbose make sure $USER has correct UID and GID
CORRECT=$(grep "[0-9][0-9]* $USER" ../etc/users.txt)
CORRECT_UID=${CORRECT[0]}
CORRECT_GID=${CORRECT[3]}
if [[ $(grep "[0-9][0-9]* $USER" ../etc/users.txt | awk '{print $1}') != $(id -u) ]]
then
    log_warning could not find user
fi

if grep -q "Added by $SCRIPTNAME" /etc/fstab
then
    log_warning already added entries to /etc/fstab
    exit
fi

# http://linoxide.com/file-system/example-linux-nfs-mount-entry-in-fstab-etcfstab/
# Main want rsize=8192,wsize=8192 for max sends
log_verbose updating fstab
sudo tee -a /etc/fstab <<<"# Added by $SCRIPTNAME on $(date)"
for pool in "$POOLS"
do
    sudo mkdir -p "/mnt/$pool"
    log_verbose adding $SERVER $pool to /mnt/$pool to fstab
    sudo tee -a /etc/fstab <<<"$SERVER:/$pool /mnt/$pool nfs4 rw,auto,timeo=14,intr 0 0"
done

log_verbose mount the new table entries
sudo mount -a
