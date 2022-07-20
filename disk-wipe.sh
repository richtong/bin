#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Completely wipe a disk including the pesky meta data left by RAID, LVM,
## Device Mapper
## https://djlab.com/2013/07/removing-raid-metadata/
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
SECURE="${SECURE:-false}"
OPTIND=1
while getopts "hdvfs" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Completely wipe a disk be careful!
			usage: $SCRIPTNAME [flags] [/dev/disk...]
			 flags: -h help
					-d debug $($DEBUGGING && echo "off" || echo "on")
					-v verbose $($VERBOSE && echo "off" || echo "on")
			       -f force the wipe (default: $FORCE)
			       -s secure erase writing zeros to the entire disk (default: $SECURE)
			 positionals: These disks appear to be available to wipe
		EOF
		"$SCRIPT_DIR/disk-info.sh" -a
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
	f)
		FORCE=true
		;;
	s)
		SECURE=true
		;;
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-fs.sh lib-util.sh
shift $((OPTIND - 1))
log_warning a very dangerous command step through carefully only runs with FORCE=true
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for disk in "$@"; do
	# http://tldp.org/LDP/abs/html/fto.html
	if [[ ! -b $disk ]]; then
		log_verbose "$disk is not a block device skipping"
		continue
	fi

	# https://www.shellhacks.com/yes-no-bash-script-prompt-confirmation/
	# https://stackoverflow.com/questions/226703/how-do-i-prompt-for-yes-no-cancel-input-in-a-linux-shell-script
	# https://stackoverflow.com/questions/3231804/in-bash-how-to-add-are-you-sure-y-n-to-any-command-or-alias
	read -r -p "Are you sure? [y/N] " response
	# make all lower case
	if [[ ! "${response,,}" =~ ^(yes|y)$ ]]; then
		continue
	fi

	# https://unix.stackexchange.com/questions/65595/how-to-know-if-a-disk-is-an-ssd-or-an-hdd
	if in_os linux; then
		# convert the by* names into /dev/sd?

		if disk_is_ssd "$disk"; then
			log_verbose "found SSD at $disk use blkdiscard to cmopletely wipe on linux"
			# https://askubuntu.com/questions/42266/what-is-the-recommended-way-to-empty-a-ssd
			sudo blkdiscard "$disk"
			continue
		fi
	fi

	block_size=512
	if in_os mac; then
		# Note that mac Disk Utility does erase this meta data properly so use
		# it. http://osxdaily.com/2016/08/30/erase-disk-command-line-mac/

		log_verbose on Mac unmount
		diskutil unmountDisk "$disk"
		log_verbose using Mac disk erase
		diskutil eraseDisk JHFS+ Untited "$disk"
		log_exit this does diskutil eraseDisk
	fi

	log_verbose "found HD at $disk use dd if=/dev/zero to wipe front and back"
	if in_os mac; then
		# awk separator allows -F to be a wild card with brackets so
		# separation is either left or rigth paren
		# awk also removes all non numeric characters by adding zero and forcing
		# type conversion, so we print the middle with by asking for field 2
		# https://stackoverflow.com/questions/11978892/what-is-the-optimal-way-to-extract-values-between-braces-in-bash-awk
		# https://gist.github.com/joeblau/ebe9adad43d9665608ff
		disk_size_in_bytes=$(diskutil information "$disk" | grep "Disk Size" | awk -F '[()]' '{print $2+0}')
		disk_in_blocks=$((disk_size_in_bytes / block_size))
	else
		# https://www.cyberciti.biz/faq/howto-find-out-or-learn-harddisk-size-in-linux-or-unix/
		disk_in_blocks="$(sudo blockdev --getsz "$disk")"
	fi

	log_verbose "$disk is $disk_in_blocks of $block_size blocks"

	length=$((2 ** 23))
	log_verbose 8MB is 2**23 bytes or $length
	blocks=$((length / block_size))
	log_verbose "$length is $blocks of $block_size blocks"
	log_warning "now erase front of $disk $blocks blocks of $block_size block size"
	if $FORCE; then
		log_warning FORCE=$FORCE so really erasing front of drive
		front="sudo dd if=/dev/zero of=$disk bs=$block_size count=$blocks"
		log_verbose "$front"
		eval "$front"
		log_warning erase front complete
	fi
	seek=$((disk_in_blocks - blocks))
	log_warning "now end of $disk at $seek with $blocks blocks of $block_size block size"
	if $FORCE; then
		log_warning FORCE=$FORCE so really erasing back of drive
		back="sudo dd if=/dev/zero of=$disk bs=$block_size count=$blocks seek=$seek"
		log_verbose "$back"
		eval "$back"
		log_warning erase back complete
	fi

	if $SECURE; then
		log_verbose beginning secure erase which takes a long time
		if in_os mac; then
			diskutil secureErase 1 "$disk"
		elif in_os linux; then
			# https://ata.wiki.kernel.org/index.php/ATA_Secure_Erase
			hdparm --security-erase "$disk"
		fi
	fi

	log_assert "[[ in_os mac && $(diskutil list "$disk" | wc -l) == 3 ]]" "Mac Disk erased"
done
