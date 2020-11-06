#!/usr/bin/env bash
##
## Figures out where the veracrypt store is
## This is needed because Dropbox will sometimes create Dropbox (Personal)
## Or Google will create something else. So this returns the first instace of
## of the veracrypt file
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
export FLAGS="${FLAGS:-""}"
SECRET_FILE="${SECRET_FILE:-"$USER.vc"}"
SECRET_DIR_ROOT="${SECRET_DIR_ROOT:-"$HOME"}"
OPTIND=1
while getopts "hdvu:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Returns on stdin the location of the veracrypt directory
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help
			           -u the file of secrets (default: $SECRET_FILE)
			           -s directory for the new volume (default: $SECRET_DIR_ROOT)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	u)
		SECRET_FILE="$OPTARG"
		;;
	s)
		SECRET_DIR_ROOT="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-fs.sh
shift $((OPTIND - 1))

# note that since we are returning on stdin we need to not write anything out
# https://www.geeksforgeeks.org/mindepth-maxdepth-linux-find-command-limiting-search-specific-directory/
# https://unix.stackexchange.com/questions/62880/how-to-stop-the-find-command-after-first-match
if ! find "$SECRET_DIR_ROOT" -maxdepth 3 -name "$SECRET_FILE" -print -quit; then
	log_error "find failed $SECRET_DIR_ROOT probably does not exist"
fi
