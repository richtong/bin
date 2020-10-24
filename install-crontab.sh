#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Use hostnamectl to set pretty hostname
## Install an hourly crontab job to run the $USER
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
JOB=${JOB:-"$SCRIPT_DIR/system-run.sh"}
ORG_NAME="${ORG_NAME:-tongfamily}"
ORG_DOMAIN="${ORG_DOMAIN:-"$ORG_NAME.com"}"
EMAIL=${EMAIL:-"$USER@$ORG_DOMAIN"}
while getopts "hdvj:u:e:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME installs a crontab job to run the scons pre build"
		echo flags: -d debug, -h help, -v verbose
		echo "       -j command to run on cronjob start (default $JOB)"
		echo "       -e email for errors from crontab job (default $EMAIL)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;&
	v)
		export VERBOSE=true
		;;
	j)
		JOB="$OPTARG"
		;;
	e)
		EMAIL="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh
# get to positionals
shift $((OPTIND - 1))

# https://askubuntu.com/questions/58575/add-lines-to-cron-from-script
# Search crontab and create if not present. Note we cannot use touch
# Note crontab will email you if there is an error
if crontab -l; then
	echo "" | crontab
fi

# Because a new crontab can be null, the grep will fail
# But we always add a newline above
if ! crontab -l | grep -q "Added by $SCRIPTNAME"; then
	log_verbose "Adding $JOB to crontab"
	# crontab fails is there is not an empty newline at the end
	(
		crontab -l
		echo -e "# Added by $SCRIPTNAME on $(date)\nMAILTO=$EMAIL\n0 * * * * $JOB\n\n"
	) |
		crontab
fi

# To start the whole thing off, make sure that the local commit
# Does not match master. Note we cannot use system_run -f because
# this never terminates for deployment machines
# log_verbose running $JOB -f $LOG_FLAGS
# "$JOB" -f $LOG_FLAGS
log_verbose forcing crontab to start by resetting src to HEAD~1
if ! cd "$WS_DIR/git/src"; then
	log_error 1 "No $WS_DIR/git/src"
fi
git reset HEAD~1
cd - || true
