#!/usr/bin/env bash
##
## Install btrfs and configure on our server
##
## See https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Storage_Administration_Guide/btrfs-integrated_volume_management.html ##
## for how to overwrite
##
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
DISKS=${DISKS:-""}
CACHE=${CACHE:-""}
POOL=${POOL:-"btrfs-pool"}
# make the default an array needs a hack
# https://stackoverflow.com/questions/27554957/how-to-set-the-default-value-of-a-variable-as-an-array
# https://unix.stackexchange.com/questions/10898/write-default-array-to-variable-in-bash
DEFAULT_SHARE=(data user)
if ((${#DEFAULT_SHARE[@]} > 0)); then SHARE=("${SHARE[@]:-${DEFAULT_SHARE[@]}}"); fi

ORG_NAME="${ORG_NAME:-"tongfamily"}"
FORCE=${FORCE-}
QUOTA=${QUOTA:-2T}
options=""
flags=""
while getopts "hdvs:f" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install btrfs and configure this as a server"
		echo "flags: -d debug, -h help"
		echo "       -s quoted list of shares (default: ${SHARE[*]})"
		echo "	     -f force the change so overwrite existing disks (default: $FORCE)"
		echo "positionals: /dev/sdb /dev/sdc ...."
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	s)
		# https://www.shellcheck.net/wiki/SC2206
		mapfile -t SHARE <<<"$OPTARG"
		;;
	f)
		if [[ ! $flags =~ -f ]]; then
			flags+=" -f"
		fi
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh lib-util.sh

set -u
shift $((OPTIND - 1))
DISKS=${DISKS:-"$@"}

if ! in_os linux; then
	log_error 1 "run on linux only"
fi

package_install btrfs-tools

if [[ -z $DISKS ]]; then
	log_error 2 "No disks on the command line, here are currently available drives $(disks_list_possible)"
fi

# shellcheck disable=SC2086
if ! disks_already_mounted $DISKS; then
	log_warning $? "drives are already mounted skipping makeing drives"
else
	# robust conversion into an array
	# https://github.com/koalaman/shellcheck/wiki/SC2206
	IFS=" " read -r -a disk <<<"$DISKS"
	log_verbose try to be smart about the pool given the number of disks
	case ${#disk[@]} in
	0)
		log_error 6 "No disks"
		;;
	1)
		layout=" $DISKS"
		;;
	2 | 3)
		layout="-m raid1 -d raid1 $DISKS"
		;;
	[4-9])
		layout="-m raid10 -d raid10 $DISKS"
		;;
	*)
		log_error 7 "Too many disks should configure manually"
		;;
	esac

	if $FORCE; then
		log_verbose forcing disk allocation so first umount all of them
		for d in $DISKS; do
			sudo umount "$d" >/dev/null
		done
	fi

	# Only way to detect if btrfs is on the disk

	if ! sudo btrfs filesystem show --all-devices | grep -q "${disk[0]}"; then
		sudo mkfs.btrfs $flags $layout $options
	fi
fi

if $VERBOSE; then
	sudo btrfs filesystem show "${disk[0]}"
fi

# $disk is the short way to refer to the first entry or ${disk[0]}
# Now mount the file system via fstab
if ! grep -q "^${disk[0]}" /etc/fstab; then
	# https://www.howtoforge.com/a-beginners-guide-to-btrfs#-using-compression-with-btrfs
	# Note we are using compression that is better than default
	# http://www.phoronix.com/scan.php?page=article&item=btrfs_lzo_2638&num=4
	sudo mkdir -p "/$POOL"
	config_add_once /etc/fstab "${disk[0]} /$POOL btrfs defaults,compress=lzo 0 1"
fi

# rerun /etc/fstab
sudo mount -a

# https://help.ubuntu.com/14.04/serverguide/network-file-system.html
log_verbose installing nfs servers and shares
package_install nfs-kernel-server
sudo touch /etc/exports
for share in "${SHARE[@]}"; do
	sudo mkdir -p "/$POOL/$share"
	# http://nfs.sourceforge.net/nfs-howto/ar01s03.html
	config_replace /etc/exports "/$POOL/$share" "/$POOL/$share *(rw,sync,no_root_squash)"
done
sudo service nfs-kernel-server start

"$SCRIPT_DIR/install-samba.sh" -p "$POOL" "${SHARE[@]}"

log_message "Each user should run ssh $HOSTNAME smbpasswd to set samba password"

# https://btrfs.wiki.kernel.org/index.php/UseCases#How_do_we_implement_quota_in_BTRFS.3F
log_verbose enable quota
for share in "${SHARE[@]}"; do
	if ! sudo btrfs subvolume "/$POOL/$share" >/dev/null; then
		sudo btrfs subvolume create "/$POOL/$share"
		sudo btrfs quota enable "/$POOL/$share"
		sudo btrfs qgroup limit "$QUOTA" "/$POOL/$share"
	fi
done

# Now set permissions so that entire organizationcan access all
sudo chown -R "$USER:$ORG_NAME" "/$POOL"
sudo chmod g+rw -R "/$POOL"

log_verbose create shares
if $VERBOSE; then
	sudo btrfs filesystem show "${disk[0]}"
	sudo btrfs subvolume show "/$POOL"
fi

log_warning You can via smb by setting sudo smbpasswd -a user-name
log_warning make sure you have run add-accounts.sh on the server to align uid
