#!/usr/bin/env bash
##
## Install dotfiles by symlink with stow
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
VERBOSE_FLAG=${VERBOSE_FLAG:-" -v "}
# we do not use readlink because it is linux specific note that this assumes the
# directory exists
DOTFILES_ROOT=${DOTFILES_ROOT:-"$(cd "$SCRIPT_DIR/../user/$USER/dotfiles" 2>/dev/null && pwd -P || echo "")"}
TARGET="${TARGET:-"$HOME"}"
while getopts "hdvt:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Install Dotfiles into a target directory using version layering

			usage: $SCRIPTNAME [ flags ] [ destinition directory ]

			flags: -d debug, -v verbose, -h help
			       -t dotfile root (default: $DOTFILES_ROOT)


			positional: the target directory (default: "$TARGET")

		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export VFLAG+=" -v "
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

mkdir -p "$TARGET"

"$SCRIPT_DIR/stow-all.sh" -s "$DOTFILES_ROOT" "$TARGET"
