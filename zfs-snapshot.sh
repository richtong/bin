#!/usr/bin/env bash
##
## Take a snapshot for today
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename $0)
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
POOL=${POOL:-zfs}
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install Take a snapshot manually
            echo "flags: -d debug, -h help"
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
source_lib lib-fs.h
shift $((OPTIND-1))

# https://briankoopman.com/zfs-automated-snapshots/
log_verbose zfs-auto-snapshot will recursively snapshot everything in $POOL
sudo zfs-autosnapshot "$POOL"

# This is the old set by step way
cd "/$POOL"
# fall through is no match
# https://www.cyberciti.biz/faq/bash-loop-over-file/
shopt -s nullglob
for directory in *
do
    log_verbose checking $directory
    snapshot="$POOL/$directory@$(date +%Y-%m-%d)"
    if ! sudo zfs list -r -t snapshot "$POOL/$directory" | grep -q $snapshot
    then
        log_verbose snapshot at $snapshot
        sudo zfs snapshot "$snapshot"
    fi
done
cd -
