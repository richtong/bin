#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## remove a standard set of users
##
##@author Rich Tong
##@returns 0 on success
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Remove test users for testing install-users.sh"
		echo flags: -d debug, -h help, -v verbose
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

# remove accounts last
for script in remove-prebuild.sh remove-agents.sh remove-accounts.sh; do
	if ! "$SCRIPT_DIR/$script" "$@"; then
		echo >&2 "$SCRIPTNAME: error $? in $script"
	fi
done
