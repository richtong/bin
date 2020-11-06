#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## Remove the prebuild artifacts
## These are mainly the .bash_rc and other lines
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
REMOVE_DIRS=${REMOVE_DIRS:-"$HOME"}
SEARCH_FOR=${SEARCH_FOR:="prebuild.sh"}
while getopts "hdvs:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Clean up  prebuild artifacts"
		echo flags: -d debug, -h help, -v verbose
		echo "       -s search for string (default: # Added by $SEARCH_FOR)"
		echo "directories to search for removals (default: $REMOVE_DIRS)"
		exit 0
		;;
	d)
		# -x is x-ray or detailed trace, -v is verbose, trap DEBUG single steps
		set -vx -o functrace
		trap '(read -p "[$BASH_SOURCE:$LINENO] $BASH_COMMAND?")' DEBUG
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	s)
		SEARCH_FOR="$OPTARG"
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
if (($# > 0)); then
	REMOVE_DIRS=("$@")
fi

# http://stackoverflow.com/questions/5227295/how-do-i-delete-all-lines-in-a-file-starting-from-after-a-matching-line
# -n no print, -i inplace and make a backup with .bak extension
echo >&2 "$SCRIPTNAME: Warning deletes all after  "Added by prebuild.sh""
echo >&2 "$SCRIPTNAME: Warning $SEARCH_FOR cannot contain bash special characters"
for d in "${REMOVE_DIRS[@]}"; do
	for f in .bashrc .bash_profile .profile; do
		sudo sed -n -i.bak "/^# Added by $SEARCH_FOR/q;p" "$d/$f"
	done
done
