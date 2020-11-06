#!/usr/bin/env bash
##
## Mounts the Private.dmg from Dropbox
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
MOUNTPOINT=${MOUNTPOINT:-/Volumes/Private}
DROPBOX=${DROPBOX:-"$HOME/Dropbox"}
ENCRYPTED="${ENCRYPTED:-$DROPBOX/Private.dmg}"
while getopts "hdve:b:" opt; do
	case "$opt" in
	h)
		echo Install secrets from Private.dmg in Dropbox
		echo "$SCRIPTNAME [flags]"
		echo "flags: -d debug, -h help"
		echo "       -b Dropbox folder location (default: $DROPBOX)"
		echo "       -e Encrypted folder location (default: $ENCRYPTED)"
		echo "If $DROPBOX not found will search in other locations"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	b)
		DROPBOX="$OPTARG"
		;;
	e)
		ENCRYPTED="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTARG - 1))

if [[ ! $OSTYPE =~ darwin ]]; then
	log_error 1 "Only runs on a Mac not $OSTYPE"
fi

if [[ ! -e "$ENCRYPTED" ]]; then
	# http://www.theinstructional.com/guides/disk-management-from-the-command-line-part-3
	hdiutil create "$ENCRYPTED" -volname "Private" \
		-srcfolder "$HOME/.ssh" \
		-size 32 -encryption AES-256 -stdinpass -fs JHFS+
	log_error 1 "no $ENCRYPTED exists you should create"
fi

if [[ ! -e "$MOUNTPOINT" ]]; then
	hdiutil attach "$ENCRYPTED"
else
	log_warning Private volume already exists using it instead
fi
