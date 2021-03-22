#!/usr/bin/env bash
##
##  Template for globally replacing statements in a Bash script
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
NEW="${NEW:-"include.sh"}"
OLD="${OLD:-"surround.sh"}"
while getopts "hdvo:n:" opt; do
	case "$opt" in
	h)
		echo Change all statements from on to another
		echo "usage: $SCRIPTNAME [ flags ]"
		echo
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -o replace this line (default: $OLD)"
		echo "       -n with this text (defualt: $NEW)"
		echo
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	o)
		OLD="$OPTARG"
		;;
	n)
		NEW="$OPTARG"
		;;
	*)
		echo >&2 "no -$opt"
		;;
	esac
done

SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh lib-util.sh
shift $((OPTIND - 1))

# do not need this code, but it let's you sed old and new from the command line simply
#for var in OLD NEW
#do
#    log_verbose setting $var to $1
#    # https://stackoverflow.com/questions/9714902/how-to-use-a-variables-value-as-other-variables-name-in-bash
#    # note we need backslashes as the eval first strips and then revaluates
#    eval $var="\${1:-\"\$$var\"}"
#    log_verbose properly escape $var
#    # https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed
#    eval $var="\$(to_sed \"\$$var\")"
#    shift
#done

ESCAPED_OLD="$(echo "$OLD" | config_to_sed)"
log_verbose "convert OLD $OLD to properly escaped to $ESCAPED_OLD"
ESCAPED_NEW="$(echo "$NEW" | config_to_sed)"
log_verbose "convert NEW $NEW to properly escaped to $ESCAPED_NEW"
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for file in "$@"; do
	# sed -i 's#if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi#if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi#'
	log_verbose "changing $ESCAPED_OLD for $ESCAPED_NEW in $file"
	if in_os mac && [[ $(command -v sed) =~ /usr/bin/sed ]]; then
		FLAGS="bak"
	fi
	sed -i ${FLAGS-} "s/$ESCAPED_OLD/$ESCAPED_NEW/g" "$file"
done
