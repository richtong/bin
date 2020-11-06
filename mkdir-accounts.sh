#!/usr/bin/env bash
##
## install the standard directory layout on a file server
## ensure that all the permissions are correct
##
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR
OPTIND=1
USER_FILE="${USER_FILE:-"$(readlink -f "$SCRIPT_DIR/../etc/users.txt")"}"
ORG_NAME="${ORG_NAME:-tongfamily}"
HOME_ROOT_DIR="${HOME_ROOT_DIR:-"/zfs/home"}"
SHARED_GROUP="${SHARED_GROUP:-"iamusers"}"
DEFAULT_USER="${DEFAULT_USER:-"ubuntu"}"
while getopts "hdvf:l:s:u:" opt; do
	case "$opt" in
	h)
		echo Install standard directory layout
		echo Put all users into a single shared group
		echo
		echo "usage: $SCRIPTNAME [flags]"
		echo
		echo "flags: -d debug -v verbose -h help"
		echo "       -f user file if no using iam-key(deprecated default: $USER_FILE)"
		echo "       -l directory location (default: $HOME_ROOT_DIR)"
		echo "       -s shared group for all users we create (default: $SHARED_GROUP)"
		echo "       -u default owner for common data folders (default: $DEFAULT_USER)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	f)
		USER_FILE="$OPTARG"
		;;
	l)
		HOME_ROOT_DIR="$OPTARG"
		;;
	s)
		SHARED_GROUP="$OPTARG"
		;;
	u)
		DEFAULT_USER="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

shift $((OPTIND - 1))
source_lib lib-install.sh

log_warning this is deprecated use iam-key instead to create user accounts
log_warning "if you do this you should make sure that lib/users.txt and"
log_warning lib/groups.text are correct!!!!!

log_verbose "putting all user accounts into $HOME_ROOT_DIR"
mkdir -p "$HOME_ROOT_DIR"

# https://www.cyberciti.biz/faq/howto-linux-add-user-to-group/
log_verbose "check and create group $SHARED_GROUP"
if ! getent passwd "$SHARED_GROUP"; then
	sudo groupadd "$SHARED_GROUP"
fi

log_verbose "check and create user $DEFAULT_USER"
if ! id -u "$DEFAULT_USER" &>/dev/null; then
	sudo useradd "$DEFAULT_USER"
	sudo usermod -a -G "$SHARED_GROUP" "$DEFAULT_USER"
fi

log_verbose "change $HOME_ROOT_DIR ownership to $DEFAULT_USER:$SHARED_GROUP"
sudo chown -R "$DEFAULT_USER:$SHARED_GROUP" "$HOME_ROOT_DIR"

log_verbose "Change permissions so only members of $SHARED_GROUP can read files"
sudo chmod ug+rw,o-w -R "$HOME_ROOT_DIR"

add_user() {
	if (($# < 3)); then return 1; fi
	local user="$1"
	local group="$2"
	local dir="$3"
	if ! id "$user" >/dev/null; then
		sudo useradd "$user"
	fi
	if id "$user" &>/dev/null && [[ ! -e $dir/$user ]]; then
		log_verbose "making $dir/$user for $user:$ORG_NAME"
		sudo mkdir -p "$dir/$user"
		sudo chown -R "$user:$group" "$dir/$user"
	fi
}

log_verbose use deprecated lib/user.txt account system
# single step trace doews not work with the read command
# Use FD 10 for input so we can single step
# shellcheck disable=SC2034
while read -u 10 -r uid user notused; do
	add_user "$user" "$HOME_ROOT_DIR"
done 10<"$USER_FILE"
