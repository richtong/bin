#!/usr/bin/env bash
##  installs a generic mac app
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
APP="${APP:-"ShiftIt"}"
URL="${URL:-""}"
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo Install a generic Mac app
		echo "usage: $SCRIPTNAME [flags] [ app [ url  ]]"
		echo flags: -d debug, -h help
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
source_lib lib-mac.sh lib-instal.sh lib-util.sh
shift $((OPTIND - 1))
APP="${1:-"$APP"}"
URL="${2:-"$URL"}"

if ! in_os mac; then
	log_exit Mac only
fi

if [[ ! -e /Applications/$APP.app ]]; then
	log_verbose "brew install $APP"
	# https://stackoverflow.com/questions/2264428/converting-string-to-lower-case-in-bash
	if cask_install "${APP,,}"; then
		log_exit "$APP installed"
	fi
fi

if [[ ! -e /Applications/$APP.app && -n ${URL:-} ]]; then
	log_verbose trhing github download
	download_url_open "$URL"
fi

log_assert "[[ -e /Applications/$APP.app ]]" "$APP installed"
