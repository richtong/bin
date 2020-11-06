#!/usr/bin/env bash
##
## Set SMB Password and login passwords
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
# readlink makes the file names absolute
USER_FILE="${USER_FILE:-"$(readlink -f "$SCRIPT_DIR/../etc/users.txt")"}"
while getopts "hdvu:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Set smb and login passwords"
		echo "usage: $SCRIPTNAME [ flags ] [ users... ]"
		echo
		echo "flags: -d debug, -h help -v verbose"
		echo "       -u user and uid file deprecated (default: $USER_FILE)"
		echo
		echo "positionals: list of user to set"
		echo "Can also pass in a list with USERS environment variable"
		echo "default is to use the sambausers list set by iam-key"
		echo
		exit
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	u)
		USER_FILE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh

if [[ ! $OSTYPE =~ linux ]]; then
	log_exit only for linux
fi

if [[ -e /etc/samba/smb.conf ]] && grep "password sync" /etc/samba/samba.conf; then
	log_exit Samba is already doing password sync with Linux PAM on Ubuntu 16.04
fi
log_verbose this is deprecated run with care

log_verbose "users set to positionals $* unless already set by environment import"
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
USERS="${USERS:-$@}"

log_verbose USERS set to sambausers
package_install members
USERS="${USERS:-"$(members sambausers)"}"

log_verbose "if no positionals, sambausers or environment fall back to the $USER_FILE"
# Note we only need the NEW_USER field
# Use awk since Note cannot read inside a read
# note we use conditional assignment so will not override if previously set
USERS=${USERS:-"$(grep '^[0-9][0-9]*' "$USER_FILE" | awk '{print $2}')"}

log_verbose "setting passwords for $USERS"
log_verbose no password sync found attempting to enable manually
log_verbose not tested and deprecated

# https://web.archive.org/web/20111009192206/http://jaka.kubje.org/infodump/2007-05-14-unix-samba-password-sync-on-debian-etch/
log_verbose synchronizing Unix password with Samba
package_install libpam-smbpass smbclient

log_verbose now connect samba to linux pam
file="/etc/pam.d/common-password"
if [[ -e $file ]]; then
	config_replace "$file" "^password.*required.*pam_unix.so" \
		"password required pam_unix.so nullok obscure min-4 max=8"
	config_add_once "$file" "^password required pam_smpass.so nullok use_authtok try_first_pass"
fi

file="/etc/pam.d/common-auth"
if [[ -e $file ]]; then
	line_replace "$file" "^auth.*required.*pam_unix.so" \
		"auth requisite pam_unix.so nullok_secure"
	line_replace "$file" "^auth.*optional.*pam_smbpass.so" \
		"auth optional pam_smbpass.so migrate"
	log_verbose this only works if you use a real password when you ssh in
fi

log_verbose allows samba smbpasswd changes to go to Linux
file="/etc/samba/smb.conf"
if [[ -e $file ]]; then
	set_config_var "unix password sync" "yes" "$file"
	set_config_var "unix password change" "yes" "$file"
fi

log_verbose changing password
file="/etc/pam.d/samba"
if [[ -e $file ]]; then
	config_add_once "$file" "@include common-auth"
	config_add_once "$file" "@include common-account"
	config_add_once "$file" "@include common-session"
	config_add_once "$file" "@include common-password"
fi

log_verbose seeting smb and login password the same is allowed
for user in $USERS; do
	# https://unix.stackexchange.com/questions/296838/whats-the-difference-between-eval-and-exec
	if ! getent passwd "$user" >/dev/null; then
		log_verbose "User $user not on machine $HOSTNAME"
		continue
	fi
	if command -v smbpasswd; then
		# https://unix.stackexchange.com/questions/107032/deleting-a-samba-user-pbdedit-vs-smbpasswd-whats-the-difference
		# pdbedit is long term tool for use reserver smdpasswd for user editing
		# their own
		prompt_user "Activate smb for $user" "sudo smbpasswd -a $user"
	fi
	# https://www.cyberciti.biz/faq/linux-resetting-a-users-password/
	# note for su we need to explicitly say root since there is no root passwd
	# prompt_user "Activate login password for $user" "sudo su root -c passwd "$user""
	# https://askubuntu.com/questions/894858/cannot-log-in-after-successful-password-change
	prompt_user "Activate login password for $user" "sudo passwd $user"
done

log_warning see https://askubuntu.com/questions/894858/cannot-log-in-after-successful-password-change

log_warning Ubuntu 16.04 this results in an authentication failure occasionally
log_verbose "sudo smbpasswd -d to delete a user from smb usage"
log_verbose "sudo su -c passwd -d to remove login password"
