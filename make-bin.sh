#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Makes an executable visible in $WS_DIR/src/bin
## assumes the client key names are the same as $USER
## Users the Tunnelblick format to keep the config and keys together
## https://tunnelblick.net/cConfigT.html#files-contained-in-a-tunnelblick-vpn-configuration
## Also makes it easy to use for the Mac OpenVPN client Tunnelblick
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: make an executable visible in src/bin"
		echo flags: -d debug, -h help, -v verbose
		echo "      -f force delete if links exist"
		echo list of files to be made visible
		exit 0
		;;
	d)
		export DEBUGGING=true
		;&
	v)
		export VERBOSE=true
		;;
	f)
		FORCE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

FORCE=${FORCE:-false}

set -u
# move positional parameters into place
shift "$((OPTIND - 1))"

relpath() {
	if (($# > 0)); then
		# http://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
		python -c \
			'import sys, os.path; print os.path.relpath(sys.argv[1], sys.argv[2])' \
			"$1" "${2:-$PWD}"
	fi
}

# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for file in "$@"; do
	log_verbose "working on $file"
	if [[ ! -e "$file" ]]; then
		log_warning "$file does not exist"
		break
	fi

	full_path=$(readlink -f "$file")
	base_name=$(basename "$file")
	command_name="${base_name%.*}"

	if ! pushd ../../local-bin >/dev/null; then
		log_error 1 "no ../../local-bin"
	fi
	if "$FORCE"; then
		rm -f "$command_name"
	fi

	log_verbose "trying to sym link $file into src/local-bin"
	if [[ ! -e "$command_name" ]]; then
		ln -s "$(relpath "$full_path")" "$command_name"
		log_verbose symlinked into src/local-bin
	fi
	popd >/dev/null || true

	if ! pushd ../../bin >/dev/null; then
		log_error 2 "no ../../bin"
	fi
	if "$FORCE"; then
		rm -f "$command_name"
	fi
	if [[ ! -e "$command_name" ]]; then
		ln -s ws-rel-cmd "$command_name"
		log_verbose symlinked into src/bin
	fi
	popd >/dev/null || true
done
