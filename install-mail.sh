#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Checks to see if mail is functioning
## Mail needs to be installed by a sudo account
## normally prebuild-agents.sh does this
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# over kill for a single flag to debug, but good practice
OPTIND=1

while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME installs mail for outbound email"
		echo flags: -d debug, -h help, -v verbose
		exit 0
		;;
	d)
		export DEBUGGING=trueh
		;&
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
# Get to positional parameters
shift "$((OPTIND - 1))"

if ! command -v ssmtp; then
	echo >&2 "$SCRIPTNAME: no ssmtp sender"
fi

log_verbose testing smtp

ssmtp ops@surround.io <<-EOF
	To: ops@surround.io
	From: $USER@surround.io
	Subject: test email

	Testing mail send

EOF
