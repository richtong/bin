#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install dotfiles by symlink with stow
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
# we do not use readlink because it is linux specific note that this assumes the
# directory exists
#DOTFILES_ROOT="${DOTFILES_ROOT:-"$(cd "$SCRIPT_DIR/../user/$USER/dotfiles" 2>/dev/null && pwd -P || echo "")"}"
DOTFILES_ROOT="${DOTFILES_ROOT:-"$SCRIPT_DIR/../user/$USER/dotfiles"}"
TARGET="${TARGET:-"$HOME"}"
while getopts "hdvt:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Install Dotfiles into a target directory using version layering

			usage: $SCRIPTNAME [ flags ] [ destinition directory ]

			flags: -h help
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
			       -t dotfile root (default: $DOTFILES_ROOT)


			positional: the target directory (default: "$TARGET")

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
	t)
		DOTFILES_ROOT="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh

shift $((OPTIND - 1))
if (($# > 0)); then
	TARGET="$1"
fi

if [[ -z $DOTFILES_ROOT ]]; then
	log_exit no dotfiles found skipping stow
fi

log_verbose "Making $TARGET"
mkdir -p "$TARGET"

log_verbose "Stowing from $DOTFILES_ROOT to $TARGET"
"$SCRIPT_DIR/stow-all.sh" -s "$DOTFILES_ROOT" "$TARGET"
