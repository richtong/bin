#!/usr/bin/env bash
#
# Install favorite fonts on the Mac
# Then mac only
#
set -u && SCRIPTNAME="$(basename "$0")"
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
NEW_HOSTNAME=${NEW_HOSTNAME:-"$HOSTNAME"}
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
FONTS="${FONTS:-"alfa-slab-one
lato
titillium
ubuntu
3270
fira-code
fira-code-nerd-font
hack
dejavusansmono-nerd-font"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install fonts
			Usage: $SCRIPTNAME flags... fonts...
			flags: -d debug, -h help -v verbose"
			fonts (default: $FONTS)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "No flag -$opt"
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh
shift $((OPTIND - 1))

if ! in_os mac; then
	log_exit Mac only
fi

if [[ $# -gt 0 ]]; then
	log_verbose "$# so replacing default $FONTS"
	FONTS="$*"
fi

# required by ubuntu font
package_install svn

log_verbose install cask-fonts
tap_install homebrew/cask-fonts
log_verbose "installing $FONTS"
for FONT in $FONTS; do
	cask_install "font-$FONT"
	log_verbose "font-$FONT installed"
done
