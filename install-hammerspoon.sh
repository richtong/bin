#!/usr/bin/env bash
##
## install hammerspoon and automatic spoon installer
## https://zzamboni.org/post/using-spoons-in-hammerspoon/
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
INIT="${INIT:-"$HOME/.hammerspoon/init.lua"}"
# note that this is case sensitive URL
REPO_URL="${REPO_URL:-"https://github.com/Hammerspoon/Spoons/raw/master/Spoons"}"
if [[ ! -v SPOONS ]]; then
	SPOONS=(
		SpoonInstall
	)
fi
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Hammerspoon, Spoon Installer and other scripts
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $VERSION)
				Positionals: Spoons in a bash array (default: ${SPOONS[*]})
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
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-config.sh

if ! in_os mac; then
	log_exit "Mac only"
fi

package_install hammerspoon

for spoon in "${SPOONS[@]}"; do
	log_verbose "download $REPO_URL/$spoon.spoon.zip"
	download_url_open "$REPO_URL/$spoon.spoon.zip"
done

# https://github.com/peterklijn/hammerspoon-shiftit#spooninstall
if ! config_mark "$INIT" "--"; then
	config_add "$INIT" <<-EOF
		hs.loadSpoon("SpoonInstall")
		spoon.SpoonInstall:andUse("WindowHalfsAndThirds")
		spoon.WindowHalfsAndThirds:bindHotkeys(
			 {
				left_half   = { {"ctrl", "alt", "cmd"}, "Left" },
				right_half  = { {"ctrl", "alt", "cmd"}, "Right" },
				top_half    = { {"ctrl", "alt", "cmd"}, "Up" },
				bottom_half = { {"ctrl", "alt", "cmd"}, "Down" },
				third_left  = { {"ctrl", "alt", "cmd"}, "5" },
				third_right = { {"ctrl", "alt", "cmd"}, "6" },
				third_up    = { {"ctrl", "alt", "cmd"}, "7" },
				third_down  = { {"ctrl", "alt", "cmd"}, "8" },
				top_left    = { {"ctrl", "alt", "cmd"}, "1" },
				top_right   = { {"ctrl", "alt", "cmd"}, "2" },
				bottom_left = { {"ctrl", "alt", "cmd"}, "3" },
				bottom_right= { {"ctrl", "alt", "cmd"}, "4" },
				max_toggle  = { {"ctrl", "alt", "cmd"}, "f" },
				max         = { {"ctrl", "alt", "cmd"}, "Up" },
				undo        = { {"ctrl", "alt", "cmd"}, "z" },
				center      = { {"ctrl", "alt", "cmd"}, "c" },
				larger      = { {        "alt", "cmd", "shift"}, "Right" },
				smaller     = { {        "alt", "cmd", "shift"}, "Left" },
			 }
		)
	EOF
fi
