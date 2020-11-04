#!/usr/bin/env bash
##
## install non-free and contrib repositories into Debian
## http://ask.xmodulo.com/install-nonfree-packages-debian.html
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
REPOS="${REPOS:-"contrib non-free"}"
LIST="${LIST:-"/etc/apt/sources.list"}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install Non-free repositories"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -r repositories to add (default: $REPOS)"
		echo "       -a apt source list (default: $LIST)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

set -u
shift $((OPTIND - 1))

if ! in_linux debian; then
	log_exit "not in debian"
fi

# massive hack, but need to make sure not to duplicate $REPO if already there
# sudo sed -i /etc/apt/sources.list \
#          -e "/^deb/s/$ $REPOS/"
#          -e "s/$REPOS $REPOS/$REPOS/"

# More elegant is to use Perl and typeaheads
# http://www.perlmonks.org/?node_id=518444
# -p means go through every line of stdin and print the parsed line
# -e means use this as the perl command, in this case a regex
# Note that grep -P gives you perl regex if you just need to search
# This also used search groups to capture the deb and the remainder
# It uses look ahead to see if there is already a string there
# Finally in Bash 4.4 the excaping of exclamation points does not work
# properly in double quote, so this uses single quotes aroung the
# And saves all the escapes of parentheses
# Note that if REPOS has a space, you need to quote the entire thing

log_verbose "installing $REPOS into $LIST"
sudo perl -i -pe 's/(^deb)(?!.*'"$REPOS"'$)(.*)/\1\2 '"$REPOS"'/' "$LIST"

sudo apt-get update
