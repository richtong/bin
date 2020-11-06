#!/usr/bin/env bash
##
## Installs yay a simple yaml parser for bash
## It does require two spaces for indents and is not general
## https://raw.githubusercontent.com/johnlane/random-toolbox/master/usr/lib/yay
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install 1Password"
		echo "flags: -d debug, -v verbose, -h help"
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
set -u
shift $((OPTIND - 1))

#
mkdir -p "$SOURCE_DIR/lib"
if ! pushd "$SOURCE_DIR/lib" >/dev/null; then
	log_error 1 "no $SOURCE_DIR/lib"
fi
curl -O L https://raw.githubusercontent.com/johnlane/random-toolbox/master/usr/lib/yay
chmod +x yay
popd >/dev/null || true
