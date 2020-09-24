#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
## Install the D-link DWA-182 wifi adapter
## Really this is the Realtek RTL8812AU or RTL8821AU driver
## @author Rich
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
FORCE="${FORCE:-false}"
OPTIND=1
while getopts "hdvf" opt
do
    case "$opt" in
        h)
            cat <<-EOF

Installs the RTL8812AU driver needed by the DWA-182 adapter and many
other 802.11ac USB wifi adapters

Will also work reportedly  for ASUS AC56

usage $SCRIPTNAME [flags]
flags: -d debug, -v verbose, -h help
       -f force the driver install even if the D-link is not found

EOF
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        f)
            FORCE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh lib-version-compare.sh

if ! in_os linux
then
    log_exit only runs on Linux
fi

if ! lsusb | grep "2001:3315 D-Link" && ! $FORCE
then
    log_verbose "No DWA-182 found"
    exit 0
fi

if in_linux ubuntu && (( $(linux_version) vergte 16.04 ))
then
    # https://ubuntuforums.org/showthread.php?t=2324552    #
    log_verbose ubuntu 16.04 or higher installing rtl8812au-dkms
    package_install rtl8812au-dkms
fi

log_verbose installing via git repo

if sudo modprobe -c | grep 8812au
then
    log_exit rtl8812au  already installed
fi

sudo apt-get install -y linux-headers-generic build-essential git
pushd "$WS_DIR/git" >/dev/null

if [ ! -e rtl8812AU_8821AU_linux ]
then
    # use https so works even if github ssh not installed
    git clone https://github.com/abperiasamy/rtl8812AU_8821AU_linux.git
fi

pushd rtl8812AU_8821AU_linux >/dev/null
make
sudo make install
sudo modprobe 8812au
popd >/dev/null
popd >/dev/null
