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
WAIT_INTERVAL=${WAIT_INTERVAL:-"10"}
WAIT_ATTEMPTS=${WAIT_ATTEMPTS:-"360"}

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

PACKAGES+=(
	gyb
)
package_install "${PACKAGES[@]}"

# note that gyb catastropically fails so need to probe for the json
# if ! gyb --email "$ARCHIVIST" --action estimate >/dev/null; then
if [[ ! -r $HOMEBREW_PREFIX/etc/gyb/client_secrets.json ]]; then
	log_verbose "login as $ARCHIVIST to create a client_secrets.json"
	rm -f "$HOMEBREW_PREFIX/etc/gyb/oauth2service.json"
	# https://github.com/GAM-team/got-your-back/wiki#performing-a-backup
	log_verbose "After login at the API & Services Dashboard"
	log_verbose "Select Credentials > + Create Client > Application Type > Desktop app"
	gyb --email "$ARCHIVIST" --action create-project

fi

log_verbose "GAM must be bash installed"
if ! command -v gam >/dev/null; then
	bash <(curl -s -S -L https://gam-shortn.appspot.com/gam-install)
fi

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
	gam create transfer "$U" "calendar,gdrive" "$ARCHIVIST" wait "$WAIT_INTERVAL" "$WAIT_ATTEMPTS"
	log_verbose "see if they completed"
	if gam print transfers olduser "$U" status inprogress | grep -q "In Progress"; then
		log_error 2 "Stuck transfers"
	fi

	log_verbose "Backup Gmail messages using GYB and upload to $ARCHIVIST's Google Drive"
	# Create a backup directory for this user
	BACKUP_DIR="/tmp/gyb_backup_${U//[@.]/_}"
	mkdir -p "$BACKUP_DIR"

	# Use GYB to backup all emails
	log_verbose "Backing up emails for $U using GYB"
	gyb --email "$U" --action backup --local-folder "$BACKUP_DIR"

	# Create a compressed archive of the backup
	ARCHIVE_NAME="${U//[@.]/_}_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
	ARCHIVE_PATH="/tmp/$ARCHIVE_NAME"
	log_verbose "Creating archive $ARCHIVE_NAME"
	tar -czf "$ARCHIVE_PATH" -C "$BACKUP_DIR" .

	# Upload the archive to ARCHIVIST's Google Drive
	log_verbose "Uploading backup to $ARCHIVIST's Google Drive"
	# Create a folder for email backups if it doesn't exist
	FOLDER_ID=$(gam user "$ARCHIVIST" show filelist query "name='Email_Backups' and mimeType='application/vnd.google-apps.folder'" | grep "^id:" | awk '{print $2}' | head -1)
	if [[ -z "$FOLDER_ID" ]]; then
		log_verbose "Creating Email_Backups folder"
		FOLDER_ID=$(gam user "$ARCHIVIST" create drivefile drivefilename "Email_Backups" mimetype gfolder | grep "id:" | awk '{print $2}')
	fi

	# Upload the archive to the folder
	gam user "$ARCHIVIST" add drivefile localfile "$ARCHIVE_PATH" parentid "$FOLDER_ID"

	# Clean up temporary files
	log_verbose "Cleaning up temporary files"
	rm -rf "$BACKUP_DIR" "$ARCHIVE_PATH"

	log_verbose "Forward all mail and leave forward on delete"

	gam user "$U" add forwardingaddress "$DEAD_LETTER_OFFICE"
	gam user "$U" forward true keep "$DEAD_LETTER_OFFICE"
	gam delete user "$U"
done
