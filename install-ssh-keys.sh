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
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

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
		cat <<-EOF
			$SCRIPTNAME: Install SSH Keys from encrypted source
			flags: -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
			positionals [user [group [ source [ destination ]]]]
				user (default: $USER)
				group (default: $GROUP)
				source (default: $SOURCE)
				destination (default: $DEST)
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
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
