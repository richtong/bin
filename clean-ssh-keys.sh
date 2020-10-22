#!/usr/bin/env bash
##
## clean ssh keys
## remove ssh keys from the ssh-add list
## remove the .ssh files
## put into archive
##
## On a Mac this is in a Private.dmg, on Linux, it uses ecryptfs
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
GROUP="${GROUP:-"$(id -gn)"}"
DEST="${DEST:-"$HOME/.ssh"}"
if [[ $OSTYPE =~ darwin ]]
then
    export PRIVATE_KEY_SOURCE_DIR=${PRIVATE_KEY_SOURCE_DIR:-"/Volumes/Private"}
else
    export PRIVATE_KEY_SOURCE_DIR=${PRIVATE_KEY_SOURCE_DIR:-"$HOME/Private"}
fi
SOURCE="${SOURCE:-"$PRIVATE_KEY_SOURCE_DIR/ssh/$USER"}"

while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
$SCRIPTNAME: Clean ssh keys from .ssh, archive and remove from ssh-add
flags: -d debug, -v verbose, -h help
        positionals [user [group [ source [ destination ]]]]
        user (default: $USER)
        group (default: $GROUP)
        source (default: $SOURCE)
        destination (default: $DEST)
EOF
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            ;;
        *)
            echo "no -$opt"
    esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-ssh.sh
log_verbose "defaults  user $USER, group $GROUP, source $SOURCE, dest $DEST"

set -u
shift $((OPTIND-1))

log_verbose looking through all positionals
if (( $# > 0 ))
then
    USER="$1"
    shift
fi

if (( $# > 0 ))
then
    GROUP="$1"
    shift
fi

if (( $# > 0 ))
then
    SOURCE="$1"
    shift
fi

if (( $# > 0 ))
then
    DEST="$1"
    shift
fi
log_verbose "after positionals processed user $USER, group $GROUP, source $SOURCE, dest $DEST"



# original direct call
# ssh_install_dir "$USER" "$GROUP" "$PRIVATE_KEY_SOURCE_DIR/ssh/$USER" "$HOME/.ssh"
log_verbose calling ssh_install_dir "$USER" "$GROUP" "$SOURCE" "$DEST"
ssh_install_dir "$USER" "$GROUP" "$SOURCE" "$DEST"
