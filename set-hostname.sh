#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Use hostnamectl to set pretty hostname
##
## See http://askubuntu.com/questions/500916/setting-hostname-on-startup
## for how to use hostnamectl rather than editing files
## With names based on https://mnx.io/blog/a-proper-server-naming-scheme/
## This just sets the "pretty name", we should also implement that
## functional name idea where we use DNS subdomains to explain the function of a
## particular machine (like tst, prd, etc).
##
## It checks to make sure we do not slect a preallocated name in hostname.txt
## Uses wordlist.txt to generate new names
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# over kill for a single flag to debug, but good practice
OPTIND=1
WORDURL=${WORDURL:-"http://web.archive.org/web/20091003023412/http://tothink.com/mnemonic/wordlist.txt"}
WORDLIST=${WORDLIST:-$(readlink -f "$SCRIPT_DIR/../etc/$(basename "$WORDURL")")}
USED_NAMES=${USED_NAMES:-$(readlink -f "$SCRIPT_DIR/../etc/hostnames.txt")}
while getopts "hdvw:u:f" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME installs a new hostname"
		echo flags: -d debug, -h help, -v verbose
		echo "     -u used hostname file (default: $USED_NAMES)"
		echo "     -w word list of unused random hostnames (default: $WORDLIST)"
		echo "     -f force the hostname change"
		echo "new hostname if there is no positional then choose a random name"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		WORDLIST="$OPTARG"
		;;
	u)
		USED_NAMES="$OPTARG"
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

FORCE=${FORCE:-false}

# new hostname is first positional parameter
# If blank then pick a random one
shift "$((OPTIND - 1))"
NEW_HOSTNAME="$1"

if [[ ! -e $WORDLIST ]]; then
	# If not wordlist.txt exists then create it
	wget -O "$WORDLIST" "$WORDURL"
fi

# do not change is we have a hostname already in the list, prevents continually
# shifting names unless we force a change
if ! $FORCE && grep "$NEW_HOSTNAME" "$WORDLIST" || grep "$NEW_HOSTNAME" "$USED_NAMES"; then
	echo "$SCRIPTNAME: $NEW_HOSTNAME is already in $WORDLIST or $USED_NAMES"
	exit 0
fi

# If there is no hostname, pick a random one
# Remove the first line which is a desription
# http://stackoverflow.com/questions/448005/whats-an-easy-way-to-read-random-line-from-a-file-in-unix-command-line
# http://unix.stackexchange.com/questions/105569/bash-replace-space-with-new-line
# This construct emulates a do-until

# the {-} construct prevents a set -u error by replacing unbound with set to
# null
if [ -z "${NEW_HOSTNAME-}" ]; then
	while true; do
		NEW_HOSTNAME=$(tail -n +2 "$WORDLIST" | tr --squeeze-repeats "[:space:]" "\n" | shuf -n 1)
		grep "$NEW_HOSTNAME" "$USED_NAMES" || break
	done
fi

log_verbose "hostname from $HOSTNAME to $NEW_HOSTNAME"
# Removed current hostname from /etc/hosts
sudo sed -i "/^127.0.0.1.*$HOSTNAME/d" /etc/hosts

# This command is new as of 13.04
# http://www.howopensource.com/2015/02/ubuntu-change-hostname/
sudo hostnamectl --no-ask-password set-hostname "$NEW_HOSTNAME"

# hostnamectl does not change /etc/hosts though
if ! grep "$NEW_HOSTNAME" /etc/hosts; then
	echo "127.0.0.1 $NEW_HOSTNAME" | sudo tee -a /etc/hosts
fi

# guard against a reinstall so do not add a new name is already there
if ! grep "$NEW_HOSTNAME" "$USED_NAMES"; then
	echo "$NEW_HOSTNAME" >>"$USED_NAMES"
fi

echo "$SCRIPTNAME: Hostname changed, you need to reboot now"
log_assert "hostname | grep \"^$NEW_HOSTNAME\"" "Host name changed"
