#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## verify docker
## @author rich
## @function verify-docker
## @return o if successful
#
# Run after docker installed as a test
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# over kill for a single flag to debug, but good practice
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME flags: -d debug -f git-lfs file"
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

# now we can check for unbound variables
set -u

if ! docker run hello-world; then
	log_exit 1 "docker did not install correctly"
fi
