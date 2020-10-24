#!/usr/bin/env bash
##
## install karabiner-elements
## Does keyboard mapping for PC keyboards used on Macs
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
CONFIG=${CONFIG:-"$HOME/.karabiner.d/configuration/karabiner.json"}
while getopts "hdvc" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install Karabiner Elements"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -c configuration file (default: $CONFIG)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	c)
		CONFIG="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u
shift $((OPTIND - 1))

log_warning using karabiner-elements as MacOS Sierra does not support regular Karabiner
log_warning this swaps the command and option keys only use when using PC keyboard on Mac
log_warning also makes the function keys works for mac hardware control keys

if ! in_os mac; then
	log_warning "For Mac only"
fi

log_verbose installing karabiner-elements
if ! find /Applications -maxdepth 1 -name "Karabiner-Elements*" -quit; then
	log_verbose brew cask install karabiner-elements
	if ! cask_install karabiner-elements; then
		download_url_open "https://pqrs.org/latest/karabiner-elements-latest.dmg"
	fi
fi

mkdir -p "$(dirname "$CONFIG")"
touch "$CONFIG"

if ! grep -q "Added by $SCRIPTNAME" "$CONFIG"; then
	cat >>"$CONFIG" <<-EOF
		{
		    "comment" : "Added by $SCRIPTNAME on $(date)",
		    "profile" : [
		        {
		            "name" : "Default profile",
		            "selected" : true,
		            "simple_modifications" : {
		                "left_option" : "left_command",
		                "left_command" : "left_option",
		                "right_option" : "right_command",
		                "right_command" : "right_option"
		                "f1" : "vk_consumer_brightness_down",
		                "f2" : "vk_consumer_brightness_up",
		                "f3": "vk_mission_control",
		                "f4" : "vk_launchpad",
		                "f5" : "vk_illumination_down",
		                "f6" : "vk_illumination_up",
		                "f7" : "vk_consumer_previous",
		                "f8" : "vk_consumer_play",
		                "f9" : "vk_consumer_next",
		                "f10" : "mute",
		                "f11" : "volume_down",
		                "f12" : "volume_up"
		            }
		        }
		    ]
		}
	EOF
fi
