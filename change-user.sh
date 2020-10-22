#!/usr/bin/env bash
##
## change uid and gid to the correct on in users.txt
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
USER_FILE=${USER_FILE:-"$WS_DIR/git/src/infra/etc/users.txt"}
OPTIND=1
while getopts "hdvu:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: change uid and gid to proper defaults"
		echo "flags: -d debug, -h help"
		echo "       -u user file (default: $USER_FILE)"
		echo "positionals: list of users to check"
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
	*)
		echo >&2 "no -$opt"
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh

shift $((OPTIND - 1))
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for user in "$@"; do
	if [[ $USER == "$user" ]]; then
		log_warning "can not change uid of current user $USER login as someone else and change"
		continue
	fi

	user_record=$(grep "[0-9][0-9]*[[:space:]]$user" "$USER_FILE")
	if [[ -z $user_record ]]; then
		log_verbose "no $user found in $USER_FILE"
		continue
	fi
	# https://github.com/koalaman/shellcheck/wiki/SC2206
	IFS=" " read -r -a user_record <<<"$user_record"
	correct_uid=${user_record[0]}
	correct_gid=${user_record[2]}

	if [[ $correct_uid != $(id -u "$user") ]]; then
		usermod -u "$correct_uid" "$user"
	fi
	if [[ $correct_gid != $(id -g "$user") ]]; then
		usermod -g "$correct_gid" "$user"
	fi
done
