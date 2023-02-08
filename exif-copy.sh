#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Copy EXIF from JPEG to another format
#
# This exists because Darktable will produce formats like JPEG-2000.jp2,
# JPEGXL.jpl and AVIF.avif files but not export the EXIT properly so if you
# export both files, it will copy the tags
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FROM_PREFIX="${FROM_PREFIX:jpeg}"
TO_PREFIX="${TO_PREFIX:avif}"
DEFAULT_PATH=("$PWD")
if ((${#DEFAULT_PATH[@]} > 0)); then FILE_PATH=("${FILE_PATH[@]}:-${DEFAULT_FILE_PATH[@]}"); fi
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvf:t:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Copy the EXIF data from one filetype $FROM_PREFIX to "$TO_PREFIX"
			usage: $SCRIPTNAME [ flags ] [files ... default: ${DEFAULT_PATH[*]}]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
			                   -f Set from file prefix (default: $FROM_PREFIX )
			                   -t Set the prefix to which you should copy the files (default: $TO_PREFIX)
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
	f)
		FROM_PREFIX="$OPTARG"
		;;
	t)
		TO_PREFIX="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh

if (($# > 0)); then
	FILE_PATH=("$@")
fi

log_verbose "Looking for .$FROM_PREFIX files in ${FILE_PATH[*]}"

# https://superuser.com/questions/566198/linux-command-find-files-and-run-command-on-them
#
for SEARCH_PATH in "${FILE_PATH[@]}"; do
	# https://itslinuxfoss.com/find-linux-files-extensions/
	find "$SEARCH_PATH" -name "*.$FROM_PREFIX" -exec exiftool -tagsfromfile "{}" -exif:all "{}" \;
done
