#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
## This script is designed to run *before* you have the git/src
## Uses Dropbox to get private keys from ecryptfs Private
##
## vi: se et ai sw=4 :
##
#
# need to use trap and not -e so bashdb works
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
FORCE=${FORCE:-false}
# which user is the source of secrets

while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Setup your Linux machine for bootup and debugging. This makes sure that on boot
			we turn off "quiet" so that you can see the boot messages and it enables the
			root password so that if you do a recovery mode you can log in as root. This is
			a security issue so make sure it is a robust password.

			usage: $SCRIPTNAME [flags..]

			flags: -d debug, -h help, -v verbose
			       -f force a new password for root

		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
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
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh
shift $((OPTIND - 1))

if [[ ! $(util_os) == linux ]]; then
	log_exit "Real linux only"
fi

if in_wsl; then 
	log_exit "Not for WSL"
fi

log_verbose configure grub for next reboot with dev flags
"$SCRIPT_DIR/install-grub.sh"
log_verbose check for sudo

# https://askubuntu.com/questions/155278/how-do-i-set-the-root-password-so-i-can-use-su-instead-of-sudo
if [[ $(sudo passwd -S root | awk '{print $2}') == P ]] && ! $FORCE; then
	log_exit root password already set choose -f if you want to overwrite
fi

log_warning set the root password which is needed if the machine borks and you are running in debug mode
sudo passwd
