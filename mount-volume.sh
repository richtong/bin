#!/usr/bin/env bash
#
# Mount SMB services automatically
# Then mac only
#
set -u && SCRIPTNAME="$(basename $0)"
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
HOST="${HOST:-Tyrell}"
VOLUME="${VOLUME:-Personal}"
SHARE="${SHARE:-//$USER@$HOST._smb._tcp.local/$VOLUME}"
MOUNTPOINT="${MOUNTPOINT:-"/Volumes/$VOLUME"}"

while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
$SCRIPTNAME: Mount drives on MacOS
parameters: drive (default: $SHARE) mountpoint (default: $MOUNTPOINT))
if only one argument then default share point is in /Volumes/ using the basename
flags: -d debug, -h help -v verbose
EOF
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
shift $((OPTIND-1))
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if [[ ! $OSTYPE =~ darwin ]]
then
    log_exit Mac only
fi

if [[ $# > 0 ]]
then
    log_verbose get the share name
    SHARE="$1"
    shift
fi

if [[ $# > 0 ]]
then
    log_verbose get mountpoint
    MOUNTPOINT="$1"
    shift
fi

if mount | grep -q "$MOUNTPOINT"
then
    log_exit "$MOUNTPOINT exists"
fi

mountpoint_dir="$(dirname "$MOUNTPOINT")"
log_verbose check to see if $mountpoint_dir needs an sudo
if ! eval $(util_sudo_if "$mountpoint_dir") mkdir -p "$MOUNTPOINT"
then
    log_error 1 could not create mount point $MOUNTPOINT
fi

log_verbose mounting $SHARE to $MOUNTPOINT
$(util_sudo_if "$mountpoint_dir") mount_smbfs "$SHARE" "$MOUNTPOINT"
