#!/usr/bin/env bash
##
## install ssh keys
## Be smart about how to install keys. For private keys link them for public
## keys it is ok to copy them
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
if [[ $OSTYPE =~ darwin ]]; then
	export PRIVATE_KEY_SOURCE_DIR=${PRIVATE_KEY_SOURCE_DIR:-"/Volumes/Private"}
else
	export PRIVATE_KEY_SOURCE_DIR=${PRIVATE_KEY_SOURCE_DIR:-"$HOME/Private"}
fi
SOURCE="${SOURCE:-"$PRIVATE_KEY_SOURCE_DIR/ssh/$USER"}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install SSH Keys from encrypted source"
		echo "flags: -d debug, -v verbose, -h help"
		echo positionals [user [group [ source [ destination ]]]]
		echo "       user (default: $USER)"
		echo "       group (default: $GROUP)"
		echo "       source (default: $SOURCE)"
		echo "       destination (default: $DEST)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-ssh.sh
log_verbose "defaults  user $USER, group $GROUP, source $SOURCE, dest $DEST"

set -u
shift $((OPTIND - 1))

log_verbose looking through all positionals
if (($# > 0)); then
	USER="$1"
	shift
fi

if (($# > 0)); then
	GROUP="$1"
	shift
fi

if (($# > 0)); then
	SOURCE="$1"
	shift
fi

if (($# > 0)); then
	DEST="$1"
	shift
fi
log_verbose "after positionals processed user $USER, group $GROUP, source $SOURCE, dest $DEST"

# original direct call
# ssh_install_dir "$USER" "$GROUP" "$PRIVATE_KEY_SOURCE_DIR/ssh/$USER" "$HOME/.ssh"
log_verbose calling ssh_install_dir "$USER" "$GROUP" "$SOURCE" "$DEST"
ssh_install_dir "$USER" "$GROUP" "$SOURCE" "$DEST"
