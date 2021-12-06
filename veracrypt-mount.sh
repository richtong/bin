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
SECRET_FILE="${SECRET_FILE:-"$SECRET_USER.vc"}"
# switch to Google Drive because Dropbox charges for >3 machines
# SECRET_VOLUME="${SECRET_DRIVE:-"Dropbox"}"
SECRET_DRIVE="${SECRET_DRIVE:-"Google Drive"}"
SECRET_MOUNT_ROOT="${SECRET_MOUNT_ROOT:-"$HOME"}"
SECRET_VOLUME="${SECRET_VOLUME:-"$HOME/$SECRET_DRIVE/$SECRET_FILE"}"
SECRET_MOUNTPOINT="${SECRET_MOUNTPOINT:-"$SECRET_MOUNT_ROOT/.secret"}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvu:" opt; do
	case "$opt" in
	h)
		cat <<EOF
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
# https://forums.fedoraforum.org/showthread.php?t=149189
# unlike linux, we can not just mount with veracrypt because veracrypt
# only supports FAT volumes and these have 777 permissions
# which are too open for ssh.
# instead first mount the veracryot volume as block device with the
# --filesystem=no and then this gets mounted in /dev as a block device
# We then use a normal MacOS mount which does do the permissions properly
# note we are using the -v option so we can figure the block device
mkdir -p "$SECRET_MOUNTPOINT"
# https://kifarunix.com/how-to-use-veracrypt-on-command-line-to-encrypt-drives-on-ubuntu-18-04/
if ! config_mark; then
	log_verbose "adding fstab entry to close permissions"
	# http://pclosmag.com/html/issues/200709/page07.html
	config_add <<EOF
# finds the first match for of secret file on any matching $SECRET_DRIVE
if ! pgrep -q "Google Drive"; then echo "Google Drive.app must be running"; fi
veracrypt_secret="\$(find -L "\$HOME" -maxdepth 3 -name "$SECRET_FILE" 2>/dev/null | grep -m 1 "$SECRET_DRIVE")"
if [[ -n \$veracrypt_secret ]] && ! veracrypt -t -l "\$veracrypt_secret" >/dev/null 2>&1
then
	# need to mount as block device with filesystem=none
	echo enter the password for the hidden volume this will take at least a minute
	veracrypt -t --pim=0 -k "" --protect-hidden=no --filesystem=none "\$veracrypt_secret"
fi
echo Enter your macOS password
mkdir -p "$SECRET_MOUNTPOINT"
# mode must be 700 need 700 for directory access and no one else can see it
veracrypt_disk="\$(veracrypt -t -v -l "\$veracrypt_secret" | awk '/^Virtual Device/ {print \$(NF)}')"
if [[ -n \$veracrypt_disk ]] && ! mount | grep -q "\$veracrypt_disk"
then
	#  mount in user space so private to a user
	sudo mount -t msdos -o -u="\$UID,-m=700" "\$veracrypt_disk" "$SECRET_MOUNTPOINT"
fi
EOF
fi
log_warning "OSX Fuse must run and be allowed in Security and Privacy"
log_verbose "now run the mount from the profile script"
source_profile
