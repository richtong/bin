#!/usr/bin/env bash
#
# Installs the proprietary nVidia driver, but no CUDA
#
# Called from bootstrap-dev but deprecated for install-nvidia.sh
#
set -e && SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
# 352 is stable for GTX9xx (aka Maxwell and Keplar)
# 367 for GTX10xx (aka Pascal)
# 375 for GTX10xxTi (aka later Pascal) if you turn off power management
# 382 fixes the above bug
DRIVER_VERSION=${DRIVER_VERSION:-DYNAMIC}
DRIVER_REPO=${DRIVER_REPO:-graphics-drivers}
NVIDIA_REPO=true
while getopts "hdvn:r:s" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install proprietary nvidia drivers
            echo "flags: -d debug -v verbose -h help"
            echo "       -n version (default: $DRIVER_VERSION)"
            echo "          note must be version 352 or greater to run CuDNN 7.5"
            echo "       -r name of special repo for drivers (default: $DRIVER_REPO)"
            echo "       -s use special NVIDIA new driver repo (currently: $NVIDIA_REPO)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        n)
            DRIVER_VERSION="$OPTARG"
            ;;
        r)
            DRIVER_REPO="$OPTARG"
            ;;
        s)
            NVIDIA_REPO=false
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u

if ! in_os linux
then
    log_verbose linux only
    exit
fi
if ! lspci | grep "VGA.*NVIDIA"
then
    log_verbose No NVIDIA adapter found with lspci
    exit 0
fi

DYNAMIC_VERSION=367
if [ -e /proc/driver/nvidia/version ]; then
    DYNAMIC_VERSION=$(cat /proc/driver/nvidia/version | sed -n 's/.*\sKernel Module\s\+\([0-9]\+\)\..*/\1/p')
fi

if [ "$DRIVER_VERSION" == "DYNAMIC" ]; then
    DRIVER_VERSION="$DYNAMIC_VERSION"
fi

#
# In some cases/some installs it is required to execute nvidia-modprobe to load kernel stack
# nvidia utilities (nvidia-smi, nvidia-docker) also perform this step
#
sudo apt-get install nvidia-modprobe
nvidia-modprobe -u && nvidia-modprobe -c 255 -c 0 -c 1 -c 2 -c 3 -c 4 -c 5 -c 6 -c 7

# FIXME - if driver is installed , but different version we want user to uninstall , reboot, reinstall
if [[ ! -e /proc/driver/nvidia/version ]] || ! grep -q "$DRIVER_VERSION" /proc/driver/nvidia/version
then

    # Install from PPA . An alternative is to wget .run file from download.nvidia.com and run it
    # Switch to new Ubuntu blessed nvidia driver repo $NVIDIA_REPO set
    # http://www.omgubuntu.co.uk/2015/08/ubuntu-nvidia-graphics-drivers-ppa-is-ready-for-action
    if $NVIDIA_REPO && ! ls /etc/apt/sources.list.d/$DRIVER_REPO-ppa*
    then
        sudo add-apt-repository ppa:$DRIVER_REPO/ppa
        sudo apt-get update
    fi

    # http://askubuntu.com/questions/319307/reliably-check-if-a-package-is-installed-or-not
    if dpkg-query -W -f'${Status}' 'nvidia-*' | grep -q "ok installed"
    then
        log_warning nvidia driver already installed
        log_warning You should sudo apt-get remove --purge nvidia-*
        log_warning and then reboot and run this script
            exit 0
        fi

        log_verbose Install nvidia version $DRIVER_VERSION
        sudo apt-get install -y nvidia-$DRIVER_VERSION

        #FIXME - ideally we won't need to reboot
        log_warning reboot now to get latest nvidia driver loaded
    else
        log_verbose "NVIDIA driver version $DRIVER_VERSION is already installed; nothing to do"
    fi

    ## For Surround.IO docker containers place driver specific binaries into well known location.That is needed for
    ## run-time container (i.e. container where we execute CUDA binaries)
    #if [[ -e /proc/driver/nvidia/version ]]
    #then
    #    echo "NVIDIA driver reported  version major : $NVIDIA_VERSION_MAJOR"
    #
    #    #FIXME - ensure the directory we map into container is cleaned first
    #    sudo rm -rf /opt/surroundio/install/bin/nvidia/*
    #    sudo rm -rf /opt/surroundio/install/lib/nvidia/*
    #    sudo rm -rf /opt/surroundio/install/lib32/nvidia/*
    #
    #    sudo mkdir -p /opt/surroundio/install/bin/nvidia
    #    sudo mkdir -p /opt/surroundio/install/lib/nvidia
    #    sudo mkdir -p /opt/surroundio/install/lib32/nvidia##
    #
    #    NVIDIA_DRIVERLIB_PATH="/usr/lib/nvidia-$DRIVER_VERSION"
    #    NVIDIA_DRIVERLIB32_PATH="/usr/lib32/nvidia-$DRIVER_VERSION"
    #
    #    # Copy driver specific libraries from driver location first
    #    sudo cp -r $NVIDIA_DRIVERLIB_PATH/* /opt/surroundio/install/lib/nvidia/
    #    sudo cp -r $NVIDIA_DRIVERLIB32_PATH/* /opt/surroundio/install/lib32/nvidia/
    #
    #    # Copy nVidia "global" libraries into well known directory, it will be set to be on LD_LIBRARY_PATH inside the container
    #    sudo cp /usr/bin/nvidia-* /opt/surroundio/install/bin/nvidia/
    #    sudo cp /usr/lib/x86_64-linux-gnu/libnvidia-opencl* /opt/surroundio/install/lib/nvidia/
    #    sudo cp /usr/lib/x86_64-linux-gnu/libcuda* /opt/surroundio/install/lib/nvidia/
    #    sudo cp /usr/lib/i386-linux-gnu/libnvidia-opencl* /opt/surroundio/install/lib32/nvidia/
    #    sudo cp /usr/lib/i386-linux-gnu/libcuda* /opt/surroundio/install/lib32/nvidia/
    #
    #fi
