#!/usr/bin/env bash
#
# Install favorite fonts on the Mac
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

NEW_HOSTNAME=${NEW_HOSTNAME:-"$HOSTNAME"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
VERSION="${VERSION:-7}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

# assumes font names do not have spaces and starts with font
# font-titillium -- no longer available
# nerd-fonts patches classic fonts with lots more glyphs
# needed for vim tools like trouble
# https://www.nerdfonts.com/
# font-3270-nerd-font - ugly and removed
# font-ubuntu-nerd-font-ugly and removed
# font-fira-code-nerd-font pretty ugly but keep
# https://itsfoss.com/fonts-linux-terminal/
# font-cascadia-code - lacks the nerd fonts needed for neovim trouble
# font-inconsolata - ugliy
# font-alfa-slab-one - not needed using google docs which has its own fonts
# font-lata - not needed not using local document editors anymore
# font-ubuntu-mono-nerd-font - kind of small
# font-jetbrains-mono-nerd-font - small
# it is between fira and hack and jetbrains
FONTS="${FONTS:-"

    font-dejavu-sans-mono-for-powerline
    font-dejavu-sans-mono-nerd-font
    font-fira-code-nerd-font
    font-hack-nerd-font
    font-jetbrains-mono-nerd-font
    font-ubuntu-mono-nerd-font

"}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Fonts with homebrew
			usage: $SCRIPTNAME [ flags ] [fonts...]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
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
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# These are the defaults
# From the represent.us presentation set
# alfa-slab-one: Decorative font for big questions
# titillium: Used on represent.us
# ubuntu: Used as Ubuntu system font
# lato: Most common font on Google Font
#
# For the best terminals fonts
# https://stackoverflow.com/questions/35328286/how-to-use-numpy-in-optional-typing
# although I still like SF Mono but fira code is nice!
# This first set are from represent.us and are really nice for presentations
# the second set are mono fonts for software
# svn is reuired for ubuntu
# note that FONTS is a string and assumes font names do not have white space
#
#

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install fonts
			Usage: $SCRIPTNAME flags... fonts...
			flags: -h help
			               -d $(! $DEBUGGING || echo "no ")debugging
			               -v $(! $VERBOSE || echo "not ")verbose

			fonts (default: $FONTS)
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
		echo "No flag -$opt"
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh lib-git.sh
shift $((OPTIND - 1))

if (($# > 0)); then
	log_verbose "$# so replacing default $FONTS"
	FONTS="$*"
fi

# required by ubuntu font
package_install svn
# log_verbose "install cask-fonts"
# tap_install homebrew/cask-fonts
log_verbose "installing $FONTS"
for FONT in $FONTS; do
	cask_install "$FONT"
done

# should no longer be needed since homebrew is on linux
if in_os linux; then
	# https://github.com/ryanoasis/nerd-fonts
	REPO_PATH="$(git_install_or_update nerd-fonts ryanoasis)"
	if ! pushd "$REPO_PATH" >/dev/null; then
		log_error 1 "nerd-fonts did not clone properly"
	fi

	for FONT in $FONTS; do
		"$WS_DIR/git/nerd-fonts/install.sh" "$FONT"
	done
fi
