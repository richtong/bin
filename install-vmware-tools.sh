#!/usr/bin/env bash
##
# Install vmware fusion guest tools
# Use standard build environment layout
## https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1022525
#
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$HOME/Downloads"}
TOOLS_CD=${TOOLS_CD:-"/media/$USER/VMware Tools"}
FORCE=${FORCE:-false}
while getopts "hdvc:f" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Post prebuild installation of packages"
		echo "flags: -d debug, -h help -v verbose"
		echo "       -c VMware Tools CD (default: $TOOLS_CD)"
		echo "       -f force an install (default: $FORCE)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		# Fall through to include verbose
		;;
	v)
		export VERBOSE=true
		;;
	c)
		TOOLS_CD="$OPTARG"
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
source_lib lib-util.sh lib-install.sh

if ! in_vmware_fusion; then
	log_exit not in VMware Fusion
fi

# In VMWare Fusion 8, we need to uninstall open-vm-tools to make
# copy and paste work properly
# http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1005436
# This check no longer works now that we need toolbox so we need to manually
# purge as we cannot tell if you ran the customer vmtools before
if dpkg -s open-vm-tools | grep -q "install ok"; then
	log_warning "open-vm-tools installed if you have not run this before then you should first sudo apt-get purge open-vm-tools"
fi

# if the tools exist, it could just require a configure
# Tools need to be rebuild after every kernel update
# So see if the tools are there but they do not work
if ! $FORCE && mountpoint -q /mnt/hgfs; then
	log_verbose "open-vm-tools working properly for mounting but if copy and paste does not work then use the force option"

	exit 0
fi

# In VMWare Fusion 8, we need to uninstall open-vm-tools to make
# copy and paste work properly
# http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1005436
if dpkg -s open-vm-tools 2>/dev/null | grep -q "install ok"; then
	sudo apt-get purge -y open-vm-tools
fi

if $FORCE && command -v vmware-uninstall-tools.pl; then
	sudo vmware-uninstall-tools.pl
fi

log_verbose vmware-tools does not correctly start in debian vmware but runs
# if sudo service vmware-tools status | grep Running
if command -v vmware-toolbox; then
	log_exit vmware present and running

fi

if command -v vmware-config-tools.pl; then
	log_verbose vmware-config-tools found but not running so config and start
	# ifconfig used by vmware and needs net-tools
	package_install net-tools
	sudo vmware-config-tools.pl
	# In the latest release you do not run this anymore
	# vmware-user
	exit 0
fi

# Otherwise we need to install them again
log_warning Then choose Virtual Machine/Settings/Shared Setting/Enable Shared Folders
log_warning Then add at least your home directory
read -rp "Please click on Mac VMWare Fusion app, Choose Virtual Machine/Install VMware Tools, press enter when done"

if [[ ! -e "$TOOLS_CD" ]]; then
	log_error 2 "No VMware Tools found, did you run select VirtualMachine/Install VMware Tools?"
fi

# prerequisites
package_install gcc make

# Note that quotes gets rid of wild cards etc
# Use -f to force the copy
# Use an array to force just the first thing found to load
tools_tar=$(find "$TOOLS_CD" -name "*.tar.gz")
cp -f "$tools_tar" "$DOWNLOAD_DIR"
if ! pushd "$DOWNLOAD_DIR" >/dev/null; then
	log_error "no $DOWNLOAD_DIR"
fi
tar xzf "$DOWNLOAD_DIR/$(basename "$tools_tar")"

log_warning make sure to say yes if asked to install the legacy driver
sudo "$DOWNLOAD_DIR/vmware-tools-distrib/vmware-install.pl"
popd >/dev/null || true

if [[ ! -e /mnt/hgfs ]]; then
	log_warning make sure Virtual Machine/Sharing/Shared Setting/Sharing Enabled is on
fi

# This is no longer needed
# http://superuser.com/questions/588304/no-mnt-hgfs-in-ubuntu-guest-under-vmware-fusion
#sudo mkdir -p /mnt/hgfs
#sudo mount -t vmhgfs .host:/ /mnt/hgfs

# http://askubuntu.com/questions/691585/copy-paste-and-dragdrop-not-working-in-vmware-machine-with-ubuntu
log_warning For Ubuntu 16.04 you now need to reboot
log_warning "For Ubuntu 14.04., sudo  apt-get install open-vm-tools-desktop to get copy and paste to work and then reboot again"

log_error 1 reboot to get drivers
