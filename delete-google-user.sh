#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
# Delete a google user, transfer all data to archivist, and forward their mail to a dead letter office
#
## @author Rich Tong
## @returns 0 on success
#
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"

DEAD_LETTER_OFFICE=${DEAD_LETTER_OFFICE:-"dead@tne.ai"}
ARCHIVIST=${ARCHIVIST:-"admin@tne.ai"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Delete user, transfer files/calendars/email to $ARCHIVIST and forward to $DEAD_LETTER_OFFICE
			usage: $SCRIPTNAME [ flags ] [ user@foo.ai user2@foo.ai... ]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose

		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;&
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

# https://chat.deepseek.com/a/chat/s/6fc205d1-ca79-4569-b942-3dc4b067174b
for U in "$@"; do
	log_verbose "Checking if user $U exists"
	if ! gam info user "$U" >/dev/null 2>&1; then
		log_verbose "User $U does not exist, skipping"
		continue
	fi
	log_verbose "Transfer GDrive and Calendar to $ARCHIVIST"
	# GAM Data Transfer syntax: https://github.com/taers232c/GAMADV-XTD3/wiki/Users-Transfer
	# Note: Gmail cannot be transferred via datatransfer, only Drive and Calendar
	gam create datatransfer "$U" "drive and docs" "$ARCHIVIST"
	gam create datatransfer "$U" calendar "$ARCHIVIST"
	log_verbose "Wait for transfers to complete"
	while gam show transfers | grep -q "IN_PROGRESS"; do
		log_verbose "Waiting for transfers to complete"
		sleep 60
	done

	log_verbose "Transfer Gmail messages to $ARCHIVIST"
	# Gmail transfer via delegation and copy - must be done before deletion
	gam user "$ARCHIVIST" delegate to "$U"
	gam user "$U" copy messages to "$ARCHIVIST" query "in:anywhere"
	gam user "$ARCHIVIST" delete delegate "$U"

	log_verbose "Forward all mail and leave forward on delete"

	gam user "$U" add forwardingaddress "$DEAD_LETTER_OFFICE"
	gam user "$U" forward true keep "$DEAD_LETTER_OFFICE"
	gam delete user "$U"
done
