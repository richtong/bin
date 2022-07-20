#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## create a basic template using the create-react-app
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
DESTS="${DESTS:-"$PWD"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Creates a basic react template
			    flags;
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
			    positional: location of applications... (default: $DESTS)"
		EOF
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
		echo "no -$opt flag" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND - 1))

if ! command -v create-react-app; then
	sudo npm install -g create-react-app
fi

if (($# > 0)); then
	DESTS="$*"
fi

# So we remmeber the dotglob state and temporarily set it so we can get globals
# http://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
# need || true because if unset then shopt -p returns an error which we do
# not need to check as we always reset to the previous state
previous_dot_glob="$(shopt -p dotglob || true)"
shopt -s dotglob
log_verbose "creating apps in $DESTS"
for dest in $DESTS; do
	base="$(basename "$dest")"
	cd "$dest"
	log_verbose "create app in $dest"
	create-react-app "$base"
	mv "$base/"* .
	rmdir "$base"
	cd -
done
eval "$previous_dot_glob"
