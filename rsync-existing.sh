#!/usr/bin/env bash
##
## Only copy new files that are already existing in the target
## This is most useful if you have say ~/ws/git/src/bin
## and just want a few install scripts in another directory like
## ~/wsr/git/src/bin so create them and run
## rsync with --existing and --update flags
## https://unix.stackexchange.com/questions/117190/best-way-to-sync-files-copy-only-existing-files-and-only-if-newer-than-target
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
FORCE="${FORCE:-false}"
FLAGS="${FLAGS:-"-av --update --existing "}"
while getopts "hdvfu:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Rsync only files that are already present in destination
			    usage: $SCRIPTNAME [ flags ] source destination
			    flags: -d debug, -v verbose, -h help"
			           -f force the copy (default: $FORCE)
			           -u use these flags (default: $FLAGS)

			This only copies files that are already present in the destination
			but which are new in the source.

			This is most useful when you have a few scripts in say ~/ws/git/src/bin
			And you want to just copy the updates into say ~/ws.restartus/git/src/bin

			Because this is a big change it defaults to a dry run, run -f to really
			copy
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	f)
		FORCE=true
		;;
	u)
		FLAGS="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if ! $FORCE; then
	FLAGS+="-n"
fi

if (($# < 2)); then
	log_error 1 "Need source and destination"
fi

# shellcheck disable=SC2086
rsync $FLAGS "$1/" "$2"
