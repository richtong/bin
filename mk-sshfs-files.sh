#!/usr/bin/env bash
##
## provide a mapping of iamusers on the local machine
## to the iamuser names
## Store in src/infra/etc/uidfile.$HOSTNAME.txt
## Store the groups in src/infra/et/gidfile.$HOSTNAME.txt
##
## To be used by sshfs with idmap=file
##
## https://sourceforge.net/p/fuse/mailman/message/30484363/
## The format of this file and shows what a local user
## say rich has what uid on the remote machine
## local user:remote uid
##
## Groups work the same way the gidfile shows how the text
## name of a local group maps to the remote machine gid
## local group:remote gid
##
## When using this make sure to not stop if there isn't a mapping
## you need to run sshfs with nomap=ignore
##
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
GROUP="${GROUP:-""}"
UIDFILE="${UIDFILE:-"infra/etc/$HOSTNAME.uidfile.txt"}"
GIDFILE="${GIDFILE:-"infra/etc/$HOSTNAME.gidfile.txt"}"
FORCE="${FORCE:-false}"
OPTIND=1
while getopts "hdvg:u:f" opt; do
	case "$opt" in
	h)
		echo "Create or update the uidfile and gidfile for iam key users for $HOSTNAME"
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -u uidfile for use by sshfile in WS_DIR (default: $UIDFILE)"
		echo "       -f overwrite the files if they exist (default: $FORCE)"
		echo "       -g which group members should we generate (default: $GROUP)"
		echo "       -s set uids for a specific group like iamusers (default: ${GROUP:-none})"
		echo
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	g)
		GROUP="$OPTARG"
		;;
	u)
		UIDFILE="$OPTARG"
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
source_lib lib-util.sh

uidfile="$SOURCE_DIR/$UIDFILE"
gidfile="$SOURCE_DIR/$GIDFILE"

log_verbose "check to see if a new $uidfile needed"
if $FORCE || [[ ! -e $uidfile ]]; then
	log_verbose "saving uids into $uidfile with FORCE=$FORCE"
	getent passwd | awk -F ':' '{print $1 ":" $3}' >"$uidfile"
fi

if [[ -n ${GROUP-} ]]; then
	log_verbose "explicitly add just selected members of $GROUP"
	for user in $(members "$GROUP"); do
		uid=$(id -u "$user")
		log_verbose "$user has a uid of $uid"
		if [[ -n ${uid-} ]]; then
			line_add_or_change "$uidfile" "$user" "$user:$uid"
			log_verbose added "$user:$uid"
		fi
	done
fi

log_verbose "check to see if we need to dump groups $gidfile"
if $FORCE || [[ ! -e $gidfile ]]; then
	log_verbose "dumping groups to $gidfile with FORCE=$FORCE"
	getent group | awk -F ':' '{print $1 ":" $3}' >"$gidfile"
fi

log_verbose reminder run with sshfs -o nomap=ignore when maps fail

log_assert "[[ -e $uidfile ]]" "$uidfile written"
log_assert "[[ -e $gidfile ]]" "$gidfile written"
