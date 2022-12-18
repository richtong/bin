#!/usr/bin/env bash
##
## install a tile window manager like compiz grid or Mac Divvy/Shiftit
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
FORCE="${FORCE:-false}"
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install quicktile tiling windown manager"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -f force the new keyboard bindings"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	f)
		FORCE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-git.sh lib-install.sh

shift $((OPTIND - 1))

if ! in_linux debian; then
	log_exit "must to debian to install"
fi

if [[ ! $(desktop_environment) =~ xfce ]]; then
	log_exit "quicktile only for debian xfce use compiz grid for ubuntu"
fi

package_install python python-gtk2 python-xlib python-dbus python-wnck

REPO_PATH="$(git_install_or_update "https://github.com/ssokolow/quicktile")"

pushd "$REPO_PATH" >/dev/null

if [[ ! -e $HOME/.config/quicktile.cfg ]]; then
	log_verbose creating configuration file
	python2 quicktile.py
	log_verbose the default settings are nonsensical as keypad cannot be overridden
	log_verbose use shiftit keys instead
	cat >"$HOME/.config/quicktile.cfg" <<-EOF
		[general]
		cfg_schema = 1
		UseWorkarea = True
		ModMask = <Ctrl><Alt>

		[keys]
		C = move-to-center
		H = horizontal-maximize
		V = vertical-maximize
		0 = maximize
		1 = top-left
		2 = top-right
		3 = bottom-left
		4 = bottom-right
		W = top
		A = left
		S = right
		Z = bottom
		X = middle
		KP_Enter = monitor-switch
	EOF
fi

# With XFCE the default bindings conflict with the workspace manager
# which uses ctrl-alt-keypad to move things to the named workspace
# http://xahlee.info/linux/linux_xfce_keyboard_shortcuts.html
log_verbose key binding set to...use -f if already in use
if "$VERBOSE"; then
	python2 quicktile.py --show-bindings
fi

log_verbose make sure we override the existing bindings only works in XFCE 4.x
log_verbose clearing works but the keyboard is still locked to settings
if $FORCE; then
	for mode in custom default; do
		for key in "/xfwm4/$mode/<Primary><Alt>KP_"{1..9}; do
			if xfconf-query -c xfce4-keyboard-shortcuts -p "$key"; then
				log_verbose "$key was set so clearing for quicktile"
				xfconf-query -c xfce4-keyboard-shortcuts -p "$key" -s ""
			fi
		done
	done
fi

log_verbose checking for quicktile.cfg file
# Note that Ctrl-Alt-D is a workspace command so use C for middle and S for right
if [[ ! -e $HOME/.config/quicktile.cfg ]]; then
	log_verbose "setting defaults that do not interfere with existing shortcuts"
	cat >"$HOME/.config/quicktile.cfg" <<-EOF
		[general]
		cfg_schema = 1
		UseWorkarea = True
		ModMask = <Ctrl><Alt>

		[keys]
		C = move-to-center
		H = horizontal-maximize
		V = vertical-maximize
		0 = maximize
		1 = top-left
		2 = top-right
		3 = bottom-left
		4 = bottom-right
		W = top
		A = left
		C = middle
		S = right
		X = bottom
		KP_Enter = monitor-switch
	EOF
fi

# https://forum.xfce.org/viewtopic.php?id=5550
log_verbose checking for autostart in XFCE
if [[ ! -e $HOME/.config/autostart/quicktile.desktop ]]; then
	log_verbose set quicktile to run automatically on next login
	mkdir -p "$HOME/.config/autostart"
	cat >"$HOME/.config/autostart/quicktile.desktop" <<-EOF
		[Desktop Entry]
		Name=Quicktile
		Exec=python2 $WS_DIR/git/quicktile/quicktile.py --daemonize
		Terminal=false
		StartupNotify=false
		Type=Application
	EOF
fi

log_verbose check if the quicktile daemon is running
if ! pgrep -a quicktile.py; then
	log_verbose start the quicktile daemon
	nohup python2 quicktile.py --daemonize &
fi

popd >/dev/null
