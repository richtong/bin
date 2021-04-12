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
	config_add "$INIT" <<EOF
-- https://www.hammerspoon.org/Spoons/SpoonInstall.html
-- mash it!
hyper = {"cmd", "alt", "ctrl"}

-- hotkeys for windows, repeated half rotates between -- 50%, 40% and 60% of screen
-- repeated thirds moves to different locations except for middle_third which
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall:andUse("WindowHalfsAndThirds", {
		hotkeys = {
			left_half   = { hyper, "Left" },
			right_half  = { hyper, "Right" },
			top_half    = { hyper, "Up" },
			bottom_half = { hyper, "Down" },
			third_left  = { hyper, "5" },
			middle_third_h = { hyper, "6" },
			third_right = { hyper, "7" },
			third_up    = { hyper, "8" },
			middle_third_v  = { hyper, "9" },
			third_down  = { hyper, "0" },
			top_left    = { hyper, "1" },
			top_right   = { hyper, "2" },
			bottom_left = { hyper, "3" },
			bottom_right= { hyper, "4" },
			max_toggle  = { hyper, "f" },
			max         = { hyper, "m" },
			undo        = { hyper, "z" },
			center      = { hyper, "c" },
		}
	}
)

-- Grid layout, hyper-g,
-- single letter moves but does not resize, double letter moves and resizes
spoon.SpoonInstall:andUse("WindowGrid", { start = true })

-- throw windows to diferrent screens with hyper left, right
-- use hyper j,k like vi mode to move windows
spoon.SpoonInstall:andUse("WindowScreenLeftAndRight", {
		hotkeys = {
			screen_left = { hyper,  "j"},
			screen_right = { hyper,  "k" },
		}
})
EOF
fi
