#!/usr/bin/env bash
## install solarized for ubuntu's gnome-terminal or Mac's terminal
##
# vi: se ai sw=4 et:
##
##@author Rich Tong
##@returns 0 on success
##
#
set -ue && SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

MAC_GIT="${MAC_GIT:-"tomislav"}"
MAC_REPO="${MAC_REPO:-"osx-terminal.app-colors-solarized"}"
XFCE_GIT="${XFCE_GIT:-"sgerrand"}"
XFCE_REPO="{XFCE_REPO:-xfce4-terminal-colors-solarized}"
GNOME_GIT="${GNOME_GIT:-"Anthony25"}"
GNOME_REPO="${GNOME_REPO:-"gnome-terminal-colors-solarized"}"
DIRCOLORS_GIT="${DIRCOLORS_GIT:-"seebi"}"
DIRCOLORS_REPO="${DIRCOLORS_REPO:-"dircolors-solarized"}"
OPTIND=1
while getopts "hdvw:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: flags: -d debug, -h help"
		echo "    -w WS directory"
		exit 0

		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	*)
		echo "-$opt not found" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-util.sh lib-install.sh lib-config.sh

set -u

log_verbose on Mac requires coreutils dircolors to start
"$SCRIPT_DIR/install-gnu.sh"

# fall through is no match
# https://www.cyberciti.biz/faq/bash-loop-over-file/
shopt -s nullglob

if [[ $OSTYPE =~ darwin ]]; then
	# https://apple.stackexchange.com/questions/63062/where-are-the-terminal-settings-stored-on-os-x
	# https://stackoverflow.com/questions/8350065/reload-com-apple-terminal-plist
	log_verbose Make directory listings the right color and vi too
	# Note we need the quotes in the search string
	if ! defaults read com.apple.Terminal "Window Settings" | grep -q 'name = "Solarized Dark"'; then
		git_install_or_update "$MAC_REPO" "$MAC_GIT"
		log_warning will open Terminal windows to when adding solarized layouts
		for terminal in "$WS_DIR/git/$MAC_REPO"/*.terminal; do
			open "$terminal"
		done
	fi
	# Mac does not have dircolors profile loaded, so add the equivalent code
	# http://www.conrad.id.au/2013/07/making-mac-os-x-usable-part-1-terminal.html
	# note in linux .bashrc called for interactive non-login shells
	# And .bash_profile called for login shells (like when you ssh in or when you login
	# for the first time on your Mac)
	# But in MacOSX the Terminal.app calls .bash_profile each time and then
	# .bashrc and with iterm2 it just calls bashrc so put it there
	#
	PROFILE="${PROFILE:-"$HOME/.bashrc"}"
	if ! config_mark "$PROFILE"; then
		log_verbose "Adding .dircolors to $PROFILE"
		log_verbose note on Mac assumes gnu path is loaded first
		config_add "$PROFILE" <<-'EOF'
			        if command -v dircolors >/dev/null; then
			            if [[ -r "$HOME/.dircolors" ]]; then eval "$(dircolors -b "$HOME/.dircolors")"
			                                            else eval "$(dircolors -b)"; fi
			            alias ls='ls --color=auto'
			            alias grep='grep --color=auto'
			            alias fgrep='fgrep --color=auto'
			            alias egrep='egrep --color=auto'
			        fi
		EOF
	fi
	# do not exit as we will install dircolors for everyone at the ned
fi
if [[ $(desktop_environment) =~ xfce ]]; then
	log_warning Note that in debian xfce implementation the
	log_verbose Application/Terminal Emulator by default
	log_verbose To use solarized start and go to Edit
	log_verbose Edit/Profile Preferences/Test and Background Color/Built in Scheme
	log_verbose select solarized light or solarized dark
	log_verbose Color Palette/Built in Schemes/Solarized
	log_verbose we also xetup xfce4-terminal
	# So we install both xfce4-terminal and gnome terminal below
	# confusing right?
	# https://github.com/sgerrand/xfce4-terminal-colors-solarized
	# https://askubuntu.com/questions/676428/change-color-scheme-for-xfce4-terminal-manually
	# Note that unlike gnome terminal there is no easy way to switch
	# themes as they are entries in the terminal.rc
	# although you can fool with the system with a wrapper that dynamically
	# changes terminal based on the command line.
	git_install_or_update "$XFCE_REPO" "$XFCE_GIT"
	# do not use install command because we do not want to overwrite
	# use the cp -n so as not to overwrite
	# https://stackoverflow.com/questions/9392735/linux-how-to-copy-but-not-overwrite
	# note quoting so the asterisk wild cards correctly
	# Each terminalrc needs to be in its own config
	for color_terminalrc in "$WS_DIR/git/$XFCE_REPO/"*/terminalrc; do
		color="$(basename "$(dirname "$color_terminalrc")")"
		color_dir="$HOME/.config-$color"
		log_verbose "$color_dir is the name of the directory $color terminal scheme"
		color_dest="$color_dir/xfce4/terminal"
		mkdir -p "$color_dest"
		cp -rn "$color_terminalrc" "$color_dest"
		log_verbose "to change to $color color scheme run"
		log_verbose "XDG_CONFIG_HOME=$color_dir xfce4-terminal"
	done

	dest="$HOME/.config/xfce4/terminal"
	dark="$HOME/.config-dark/xfce4/terminal"
	log_verbose "if no configuration default to dark in $dest"
	mkdir -p "$dest"
	if [[ ! -e $dest/terminalrc && -e $dark/terminalrc ]]; then
		mkdir -p "$dest"
		cp -n "$dark/terminalrc" "$dest"
	fi
	log_verbose "to permanently change overwrite $dest/terminalrc"
fi

if [[ $(desktop_environment) =~ (xfce|unity|gnome) ]]; then
	# For the ubuntu local graphical Unity terminal which uses gnome-terminal
	# Also for debian 9 xfce4 which uses gnome-terminal sometimes so also install
	git_install_or_update "$GNOME_REPO" "$GNOME_GIT"
	# Installs the dark vs light scheme into the Default terminal profile
	# This only works if Default is defined, for new installs it is Undefined,
	# so do not set dark, just install
	#"$WS_DIR/git/$GNOME_REPO/install.sh" -p Default -s dark

	# https://github.com/Anthony25/gnome-terminal-colors-solarized
	log_verbose for gnome terminal need dconf-cli setup
	package_install dconf-cli
	log_verbose install into gnome terminal but we cannot tell a profile name
	"$WS_DIR/git/$GNOME_REPO/install.sh" --scheme dark --skip-dircolors

	for theme in light dark; do
		log_warning "to switch to $theme scheme run $WS_DIR/git/$GNOME_REPO/set-$theme.sh"
	done

fi

log_verbose for all systems install solarized directory colors
# Make directory listings the right color
git_install_or_update "$DIRCOLORS_REPO" "$DIRCOLORS_GIT"
log_verbose checking for ~/.dircolors
if [[ ! -e "$HOME/.dircolors" ]]; then
	ln -rs "$WS_DIR/git/$DIRCOLORS_REPO/dircolors.ansi-universal" "$HOME/.dircolors"
	log_verbose "source $HOME/.bashrc to enable dircolors for ls or"
	log_verbose "restart the shell"
fi
if [[ ! -e $HOME/.dir_colors ]]; then
	log_verbose on other systems it is dir_colors so softlink
	ln -s "$HOME/.dircolors" "$HOME/.dir_colors"
fi
