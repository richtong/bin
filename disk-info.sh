#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Disk information
## https://www.cyberciti.biz/faq/find-hard-disk-hardware-specs-on-linux/
## https://wiki.archlinux.org/index.php/persistent_block_device_naming
##
## Disk information can come from different places
##
# /dev/disk? or /dev/sd? but these will move depending on boot order
# /dev/disk/by-id this gloms together controller and disk information so it
# doesn't move unless you change controllers
# /dev/disk/path works for large systems where you have big disk subsystems so
# easier to refer to them by the hardware path
#
# VMWare Fusion doesn't honor all of these methods, only the /dev/sd? seems
# reliable. Just as with MacoS where only have /dev/disk?
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
ALL=${ALL:-false}
INDENT=${INDENT:-8}
OPTIND=1
while getopts "hdvaw:" opt; do
	case "$opt" in
	h)
		echo Detailed information on valid disks
		echo
		echo "usage: $SCRIPTNAME [flags]"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -a print out all the information (default: $ALL)"
		echo "       -w indent width for pretty output (default: $INDENT)"
		echo
		echo "In VMWare Fusion, use /dev/disk/by-uuid or /dev/sd?"
		echo "On Ubuntu, use /dev/disk/by-id"
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	a)
		ALL=true
		;;
	w)
		INDENT="$OPTARG"
		;;
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-fs.sh
shift $((OPTIND - 1))

# if in_mac
# then
#     name=disk
# else
#     # sd is default name for modern linux devices actually stands for scsi disk
#     name=sd
# fi
# basename -a $(find /dev -name "$name?" 2>/dev/null) | indent_output "$INDENT"

log_verbose find valid names of disks
# instead of this command, use more sophisticated version
disks_list_possible | indent_output "$INDENT"

if $ALL; then
	echo
	if in_os mac; then
		diskutil list | indent_output "$INDENT"
	else
		package_install lshw
		log_warning lshw can take a long time on ubuntu real machine
		sudo lshw -short -C disk
	fi
fi
