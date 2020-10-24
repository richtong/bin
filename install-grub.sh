#!/usr/bin/env bash
##
## Makes grub display the boot sequence
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-" -v "}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs grub so it is not silent
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"

		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh lib-util.sh

shift $((OPTIND - 1))

if ! in_os linux; then
	log_exit Linux only
fi

log_verbose when booting try to get to the terminal window by typing CTRL-ALT-F1
log_verbose which will get you to tty1, as an aside tty6 is the graphical shell CTRL-ALT-F6
log_verbose Look at the /var/log/syslog for Failed and see what is happening, most
# https://askubuntu.com/questions/477821/how-can-i-permanently-remove-the-boot-option-quiet-splash.

log_verbose remove the word quiet from GRUB_CMDLINE_LINUX_DEFAULT
modify_config_var GRUB_CMDLINE_LINUX_DEFAULT quiet "" /etc/default/grub

sudo update-grub
log_verbose reboot when you want the grub change to take effect
