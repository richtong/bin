#!/usr/bin/env bash
#
# Rsync over a directory to a target
# Creates the hashes for file systems
# check the hashdeep
# Then mac only
#
set -u && SCRIPTNAME="$(basename $0)"
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
#
# https://serverfault.com/questions/211005/rsync-difference-between-checksum-and-ignore-times-options
# -a means copy all and -P means show progress bar
# -c use checksum and not just a date and size check
# https://www.jafdip.com/how-to-fix-rsync-error-code-23-on-mac-os-x/
# -v verbose to catch permission errors
FLAGS="${FLAGS:-" -acP "}"

HASHFLAGS="${HASHFLAGS:=" -c sha256 -rl "}"
DRYRUN="${DRYRUN:-false}"
AUDIT_ONLY="${AUDIT_ONLY:-false}"

while getopts "hdvnf:s:a" opt
do
    case "$opt" in
        h)
            cat <<-EOF
$SCRIPTNAME: Copy from source to destination and do a hashdeep comparision
parameters: src dest
flags: -d debug, -h help -v verbose
       -n dry ruN just see what it would do (default: $DRYRUN)
       -f rsync Flags (default: $FLAGS)
       -s haShdeep flags (default: $HASHFLAGS)
       -a Audit only, assume hashes are created (default: $AUDIT_ONLY)
EOF
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        f)
            FLAGS="$OPTARG"
            ;;
        s)
            HASHFLAGS="$OPTARG"
            ;;
        n)
            DRYRUN=true
            ;;
        a)
            AUDIT_ONLY=true
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
# source_lib lib-config.sh

if [[ ! $OSTYPE =~ darwin ]]
then
    log_exit Mac only
fi

if $DRYRUN
then
    FLAGS+=" -n "
fi

# https://stackoverflow.com/questions/5265702/how-to-get-full-path-of-a-file
# make sure that they both exist or readlink will fail
log_verbose checking for source at $1
if $VERBOSE && [[ -e $1 ]]
then
    log_verbose $1 exists
fi
if [[ ! -e $1 ]]
then
    log_error 1 Source does not exist $1
fi
log_verbose source exists
SRC="$(readlink -f "$1")"
log_verbose source is $SRC
log_verbose making sure we have the destination $2
mkdir -p "$2"
DST="$(readlink -f "$2")"
log_verbose destination is $DST
log_verbose get the full path names of $SRC and $DST
log_verbose we want all the subdirectorys of $SRC to be in $DST with flags $FLAGS

if $VERBOSE
then
    log_verbose adding RSYNC flags -vv
    FLAGS+=" -vv "
fi

log_verbose exporting HASHFLAGS as $HASHFLAGS
export HASHFLAGS
if $AUDIT_ONLY
then
    log_verbose audit only is on, so skip rsync
else
    # https://discussions.apple.com/thread/5639804
    # https://www.jafdip.com/how-to-fix-rsync-error-code-23-on-mac-os-x/
    # Tried to update to v3.x rsync but still hangs
    if ! rsync $FLAGS "$SRC"/ "$DST"
    then
        log_verbose rsync failed with error $#
        for dir in "$SRC" "$DST"
        do
            if [[ ! -e $dir ]]
            then
                log_warning $dir disappeared try running mount_smbfs to get it back
                log_error 1 sometimes the volume then reappears might be bug in Synology or MacOS so try restart
                fi
            done
            log_warning continuing assuming it was a file attribute problem
        fi

        "$SCRIPT_DIR/hashdeep-create.sh" "$SRC" "$DST"
    fi

    "$SCRIPT_DIR/hashdeep-audit.sh" "$SRC" "$DST"
