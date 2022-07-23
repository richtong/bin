#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## remove a standard set of users
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdvw:g:u:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Remove test users for testing install-users.sh"
		echo flags: -d debug, -h help, -v verbose
		echo "  -g list of new groups in a text file"
		echo "  -u user and uid file"
		exit 0
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
	g)
		GROUP_FILE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

USER_FILE=${USER_FILE:-"$SCRIPT_DIR/../etc/users.txt"}
GROUP_FILE=${GROUP_FILE:-"$SCRIPT_DIR/../etc/groups.txt"}

set -u

# looks wierd, but we pipe in the file at the bottom
# http://linuxpoison.blogspot.com/2012/08/bash-script-how-read-file-line-by-line.html
# Also this means we cannot use -d
# So comment out the while do and done and use these variables to check internal
# flow
# NEW_UID=8003
# NEW_GROUP=tongfamily
# NEW_USER=deploy
# EXTRA_GROUPS=ops,sudo,docker

debug_off
# Using unneeded makes this script insensitive to other field changes
# shellcheck disable=SC2034
while read -r NEW_UID NEW_USER UNNEEDED; do

	# Skip comment lines or existing users
	[[ $NEW_UID =~ ^# || -z $NEW_UID ]] && continue
	$VERBOSE && echo processing "$NEW_UID $NEW_USER"

	# Do not delete the current user!
	[ "$NEW_USER" = "$USER" ] && continue

	# remove if they exist
	if getent passwd "$NEW_USER"; then
		$VERBOSE && echo "deleting $NEW_USER"
		sudo deluser "$NEW_USER"
	fi

done <"$USER_FILE"
debug_on

# Now create the groups
# Note the file being read is at the done stattment!
# http://askubuntu.com/questions/515103/how-to-display-all-user-and-groups-by-command
#
# To debug remove comment out the while/do/done lines and add these lines
# NEW_GROUP=ops
# NEW_GID=8000
# Use FD 10 for input so we can still single step properly with lib_debug
# shellcheck disable=SC2034
while read -u 10 -r NEW_GID NEW_GROUP PASSWORD_LESS_SUDO; do

	# Skip comment or blank lines or existing users
	[[ $NEW_GID =~ ^# || -z $NEW_GID ]] && continue
	# do not delet vital groups
	[[ $NEW_GROUP == "$(id -u)" ]] && continue

	$VERBOSE && echo "processing $NEW_GID $NEW_GROUP"

	if getent group "$NEW_GROUP"; then
		$VERBOSE && echo "deleting $NEW_GROUP"
		sudo delgroup "$NEW_GROUP"
	fi

done 10<"$GROUP_FILE"
