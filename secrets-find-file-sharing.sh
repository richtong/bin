#!/usr/bin/env bash
##
## Finds Dropbox, Google Drive or OneDrive
## Because Dropbox can be in "Dropbox"
## Or with the new personal vs corporate feature it might be in
## Dropbox (Personal) or Dropbox (_Name of company)
##
##
##@author Rich Tong
##@returns 0 on success
##@stdout name of folders in order
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
FILE_SHARING_SERVICES[0]="${FILE_SHARING_SERVICES[0]:-"Dropbox"}"
FILE_SHARING_SERVICES[1]="${FILE_SHARING_SERVICES[1]:-"Google Drive"}"
FILE_SHARING_SERVICES[2]="${FILE_SHARING_SERVICES[2]:-"OneDrive"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo Finds the list of file synchronization diretories
		echo "usage: $SCRIPTNAME [ flags ] file sharing services..."
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo "stdout: list of folders"
		echo "positionals: file sharing service directory prefixes"
		echo "defaults:"
		printf '    %s\n' "${FILE_SHARING_SERVICES[@]}"
		echo
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
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))

if (($# > 1)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	FILE_SHARING_SERVICES=(*"$@")
fi

# this works because the file Dropbox is always going to be alphabetically ahead of "Dropbox (*)"
# Note we could also use "ls -d "$HOME/Dropbox*""
log_verbose finding file sync services
# https://stackoverflow.com/questions/6041596/how-to-output-file-names-surrounded-with-quotes-in-single-line
# Need a parenthesis so that the printf applies to everything found
for sharing_service in "${FILE_SHARING_SERVICES[@]}"; do
	log_verbose "look for $sharing_service"
	find "$HOME" -maxdepth 1 -name "$sharing_service*" -print
done
