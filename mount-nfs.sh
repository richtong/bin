#!/usr/bin/env bash
##
## temporary mount of NFS not persistent across reboots
##
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
SERVER=${SERVER:-"ai.local"}
POOL=${POOL:-"zfs"}
if [[ $OSTYPE =~ darwin ]]
then
    MOUNTPOINT=${MOUNTPOINT:-"/Network"}
else
    MOUNTPOINT=${MOUNTPOINT:-"/mnt"}
fi
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install 1Password
            echo "flags: -d debug, -h help"
            echo "positional: server pool mountpoint (default $SERVER $POOL $MOUNTPOINT)"
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

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

shift $((OPTIND-1))
SERVER=${1:-"$SERVER"}
POOL=${2:-"$POOL"}
MOUNTPOINT=${3:-"$MOUNTPOINT"}

set -u

sudo mkdir -p "$MOUNTPOINT/$POOL"
# http://jose-manuel.me/2013/03/how-to-mount-a-nfs-in-mac-os-x-mountain-lion/
sudo mount -t nfs -o resvport,proto=tcp,port=2049,rw "$SERVER:/$POOL" "$MOUNTPOINT/$POOL"
