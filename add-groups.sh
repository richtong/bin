#!/usr/bin/env bash
##
## This is a experimental so it just takes things from a local file
## We longer term would want to connect to AWS IAM and use it
##
## If we find a user with the wrong uid or gid, we move them
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
GROUP_FILE="${GROUP_FILE:-"$(readlink -f "$SCRIPT_DIR/../etc/groups.txt")"}"
while getopts "hdvg:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: adds the standard groups for our corporate machines
			        flags: -h help
			                    -g list of new groups in a text file (default: $GROUP_FILE)
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	g)
		GROUP_FILE="$OPTARG"
		;;
	*)
		echo "no -$opt"
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u

# Now create the groups
# Note the file being read is at the done stattment!
# http://askubuntu.com/questions/515103/how-to-display-all-user-and-groups-by-command
#
# To debug remove comment out the while/do/done lines and add these lines
# NEW_GROUP=ops
# NEW_GID=8000
add_group() {
	if [[ -z $NEW_GID || $NEW_GID =~ ^# ]]; then
		log_verbose skipping blank line or comment line with a #
		return
	fi

	log_verbose "Group: $NEW_GID $NEW_GROUP $NO_PASSWORD_SUDO"

	if ! getent group "$NEW_GROUP"; then
		log_verbose "groupadd -g $NEW_GID $NEW_GROUP"
		sudo groupadd -g "$NEW_GID" "$NEW_GROUP"
	else
		OLD_GID=$(getent group "$NEW_GROUP" | cut -d ':' -f 3)
		if (("$OLD_GID" != "$NEW_GID")); then
			log_verbose "moving $NEW_GROUP from $OLD_GID to $NEW_GID"
			sudo groupmod -g "$NEW_GID" "$NEW_GROUP"
			# http://askubuntu.com/questions/312919/how-to-change-user-gid-and-uid-in-ubuntu-13-04
			log_verbose change the groups in the home directory, but not globally
			log_verbose "you could run find / -group $OLD_GID -exec chgrp -h $NEW_GID {} \;"
			log_verbose to change everything
			find "$HOME" -group "$OLD_GID" -exec chgrp -h "$NEW_GID" {} \;
		fi
	fi

	# see if we need to add no password sudo line
	SUDOERS_FILE="/etc/sudoers.d/10-$NEW_GROUP"
	if [[ $NO_PASSWORD_SUDO == true && (! -e $SUDOERS_FILE) ]]; then
		sudo tee "$SUDOERS_FILE" <<<"%$NEW_GROUP ALL=(ALL:ALL) NOPASSWD:ALL" >/dev/null
		sudo chmod 440 "$SUDOERS_FILE"
	fi

}

# For debug run once in single step mode
# turned off by default
if $DEBUGGING; then
	NEW_GID=9000
	NEW_GROUP=dev
	NO_PASSWORD_SUDO=true
	add_group
fi

# Single stepping does not work with `read` so disable
# By using a different file descriptor 10
while read -u 10 -r NEW_GID NEW_GROUP NO_PASSWORD_SUDO; do
	add_group

done 10<"$GROUP_FILE"
