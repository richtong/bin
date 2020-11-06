#!/usr/bin/env bash
##
## Mounts a veracrypt volume to a mountpoint
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
SECRET_USER="${SECRET_USER:-"$USER"}"
SECRET_VOLUME="${SECRET_VOLUME:-"$HOME/Dropbox/$SECRET_USER.vc"}"
if [[ $OSTYPE =~ darwin ]]; then
	SECRET_MOUNTPOINT="${SECRET_MOUNTPOINT:-"/Volumes/$SECRET_USER.vc"}"
else
	SECRET_MOUNTPOINT="${SECRET_MOUNTPOINT:-"/media/$SECRET_USER.vc"}"
fi
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvu:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			    Mount a veracrypt volume to a mount point and sets automount

			usage: $SCRIPTNAME [ flags ] [ volume [mountpoint]]

			flags: -d debug, -v verbose, -h help
			       -u secret user (default: $SECRET_USER)


			positionals:
			      VeraCrypt volume location (default: $SECRET_VOLUME)
			      Mointpoint for volume (default: $SECRET_MOUNTPOINT)
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
	u)
		SECRET_USER="$OPTARG"
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

if (($# > 0)); then
	SECRET_VOLUME="$1"
fi

if (($# > 1)); then
	SECRET_MOUNTPOINT="$2"
fi

# MacOS fails if you do this
if [[ $OSTYPE =~ linux ]]; then
	sudo mkdir -p "$SECRET_MOUNTPOINT"
	log_verbose "add to $(config_profile) and make sure it is before the keychain commands"

	if ! config_mark; then
		log_verbose "adding mounting to the $(config_profile)"
		log_verbose in Linux, the FAT partition is mounted with mask 700 by default
		config_add <<-EOF
			if ! veracrypt -t -l "$SECRET_MOUNTPOINT" >/dev/null 2>&1
			then
			    echo now enter the password for the hidden volume this will at least a minute
			    # https://forums.macrumors.com/threads/can-not-mount-truecrypt-container-hdiutil-attach-failed-no-mountable-file.1689590/
			    veracrypt -t --pim=0 -k "" --protect-hidden=no "$SECRET_VOLUME" "$SECRET_MOUNTPOINT"
			fi
		EOF
	fi

	source_profile
	log_exit "Linux mounted"
fi

log_verbose Mac install
# https://serverfault.com/questions/81746/bypass-ssh-key-file-permission-check/82282#82282
# There is a MacOS bug where the permissions are default set to 777 because fat
# has no permissions at all. Solution is to add an entry to /etc/fstab which
# fixes this
# https://forums.fedoraforum.org/showthread.php?t=149189
# need --filesystem=none which does not mount the file system it just
# becomes a block device you can then use that device if you get the hdiutil
# bug so we do the Mac mount in two steps, first mount the block device
# then mount the block device with correct msdos parameters
#
# We do the dual phase mount because there is a bug in veracrypt for the Mac
# which prevents the hdiutil from working, so we use unix mount instead

if ! config_mark; then
	log_verbose adding fstab entry to close permissions
	# http://pclosmag.com/html/issues/200709/page07.html
	config_add <<-EOF
		if ! veracrypt -t -l "$SECRET_VOLUME" >/dev/null 2>&1
		then
		    # need to mount as block device with filesystem=none
		    echo enter the password for the hidden volume this will take at least a minute
		    veracrypt -t --pim=0 -k "" --protect-hidden=no --filesystem=none "$SECRET_VOLUME"
		fi
		# https://serverfault.com/questions/81746/bypass-ssh-key-file-permission-check/82282#82282
		# for parameters needed for msdos fat partitions
		# Need to look the second to last field because if the volume has a space cut will not work
		veracrypt_disk="\$(veracrypt -t -l "$SECRET_VOLUME" | awk '{print \$(NF-1)}')"
		if ! mount | grep -q "\$veracrypt_disk"
		then
		    echo Enter your macOS password
		    sudo mkdir -p "$SECRET_MOUNTPOINT"
		    # mode must be 700 need 700 for directory access and no one else can see it
		    sudo mount -t msdos -o -u=\$(id -u),-m=700 "\$veracrypt_disk" "$SECRET_MOUNTPOINT"
		fi
	EOF
fi

log_verbose now run the mount from the profile script
source_profile
