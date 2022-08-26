#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install Google Chrome on MacOS and Debian systems
## https://itsfoss.com/install-chrome-ubuntu/
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
export FLAGS="${FLAGS:-""}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Google Chrome
			usage: $SCRIPTNAME [ flags ]
			flags:
					-h help
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
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
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh

if in_os mac; then
	package_install google-chrome
elif in_os linux; then
	URL="${URL:-"https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"}"
	DEB="${DEB:-"$(basename "$URL")"}"
	log_verbose "downloading $DEB from $URL"
	deb_install "$URL" "$DEB"
fi