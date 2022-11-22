#!/usr/bin/env bash
##
## remove nvidia drivers
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdvw:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Remove nvidia drivers"
		echo "flags: -d debug, -h help"
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

# https://wiki.debian.org/NvidiaGraphicsDrivers#nvidia-detect
if in_linux debian; then
	# note the period, this means delete all
	log_warning this does not seem to work if gnome-session does not login
	log_warning only a complete reinstall seems to work

	sudo apt-get purge nvidia.
    if [[ $(desktop_environment) =~ gnome ]]; then
		# hangs the machine on debian 9
		/etc/init.d/gdm3 stop
	fi
	sudo apt-get install --reinstall xserver-xorg
	sudo apt-get install --reinstall xserver-xorg-video-nouveau
	sudo killall Xorg
	# forces a boot to main login
	log_warning reinstall complete reoobt for it to take effect
	log_warning after reboot run X -configure
fi

if in_linux ubuntu; then
	# https://unix.stackexchange.com/questions/144871/remove-all-nvidia-files
	log_verbose remove all nvidia
	sudo apt-get remove --purge "nvidia-*"
	# https://askubuntu.com/questions/206283/how-can-i-uninstall-a-nvidia-driver-completely
	sudo rm /etc/X11/xorg.conf

fi
