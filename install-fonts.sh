#!/usr/bin/env bash
#
# Install favorite fonts on the Mac
# Then mac only
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
NEW_HOSTNAME=${NEW_HOSTNAME:-"$HOSTNAME"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
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
FONTS="${FONTS:-"

    alfa-slab-one
    lato
    titillium
    ubuntu
    3270
    fira-code
    fira-code-nerd-font
    hack
    dejavusansmono-nerd-font

"}"

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

if in_os mac; then

	# required by ubuntu font
	package_install svn
	log_verbose "install cask-fonts"
	tap_install homebrew/cask-fonts
	log_verbose "installing $FONTS"
	for FONT in $FONTS; do
		cask_install "font-$FONT"
		log_verbose "font-$FONT installed"
	done
elif in_os linux; then
	# https://github.com/ryanoasis/nerd-fonts
	git_install_or_update nerd-fonts ryanoasis
	if ! pushd "$WS_DIR/git/nerd-fonts" >/dev/null; then
		log_error 1 "nerd-fonts did not clone properly"
	fi

	for FONT in $FONTS; do
		"$WS_DIR/git/nerd-fonts/install.sh" "$FONT"
	done
fi
