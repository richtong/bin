#!/usr/bin/env bash
##
## install Tiling window manager
## rectange for Mac
## compiz for Ubuntu Unity for older versions of Ubuntu before 18.04
## quicktile for Debian
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

OPTIND=1
VERSION="${VERSION:-7}"
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Tiling Window Manager
			    usage: $SCRIPTNAME [ flags ]
				flags: -h help"
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
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
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if in_os mac; then
	package_install rectangle
	log_warning "If using dotfiles, then symlink ~/Library/Preferences/com.knollsoft.Rectangle.plist"
elif in_os linux && ! in_os docker; then
	# if the two listed are not good enough try i3
	# https://github.com/Airblader/i3/wiki/installation
	#apt_repository_install ppa:regolith-linux/release
	#package_install i3-gaps
	log_verbose "checking and adding tiling window managers"
	if [[ $(desktop_environment) =~ gnome ]]; then
		# https://addons.mozilla.org/en-US/firefox/addon/gnome-shell-integration/

		# https://github.com/gTile/gTile
		# https://wiki.gnome.org/Projects/GnomeShellIntegration
		# https://bugs.launchpad.net/ubuntu/+source/chrome-gnome-shell/+bug/1983851
		# chrome-gnome-shell is in Ubuntu 20.04 as version 10
        # gnome-browser-connector is in Ubuntu 22.04 and higher as version 42,
        # 43....
		package_install chrome-gnome-shell gnome-tweaks
		#package_install gnome-browser-connector gnome-tweaks

		log_verbose "Must manually install Gnoe Tweaks"
        log_verbose "Click on for gtile"
        util_web_open "https://extensions.gnome.org/extension/28/gtile/"

	elif [[ $(desktop_environment) =~ unity ]]; then
		log_verbose "install Compiz Grid allows keyboard shortcuts to move windows around"
		package_install compizconfig-settings-manager
	elif [[ $(desktop_environment) =~ xfce ]]; then
		log_verbose if in debian assume running xfce so need quicktile
		"$BIN_DIR/install_quicktile.sh"
	fi
	log_verbose "finish window manager install"
fi
