#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
# Installs the proprietary nVidia drivers
# Does not install CUDA
#
set -ue && SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
# As of September 2017
# 304 will not install on a GT730 says too old changing to 340 same as 8 and 9
#
# As of July 2017
# 375 is the default install of Debian 9 release July 2017
# From nvidia website, 375 is the long lived release
# 381 has a fixed Linux power management bug
#
# As of March 2017
# 352 is stable for GTX9xx (aka Maxwell and Keplar)
# 367 for GTX10xx (aka Pascal aka GP*) which is not yet in the ppa as of Aug-16
# 367 seems to fail for Ubuntu 14.04.5
# 370 is not in the list and seems to get overwritten on Ubuntu
# Current official release: `nvidia-370` (370.28)
#
# From the PPA as of 24-Jan-2017
# Current long-lived branch release: `nvidia-367` (367.57)
# For Maxwell GeForce 8 and 9 series (code name GF, GK, GM*) GPUs use `nvidia-340` (340.98)
# For GeForce 6 and 7 series GPUs (code name GK, GF )use `nvidia-304` (304.132)
#
# http://www.linuxjournal.com/content/bash-associative-arrays
declare -A DRIVER_GTX
DRIVER_GTX[6]=${DRIVER_GTX[6]:-304}
DRIVER_GTX[7]=${DRIVER_GTX[7]:-340}
DRIVER_GTX[8]=${DRIVER_GTX[8]:-340}
DRIVER_GTX[9]=${DRIVER_GTX[9]:-340}
DRIVER_GTX[10]=${DRIVER_GTX[10]:-375}
DEFAULT_MODEL=${DEFAULT_MODEL:-10}
DRIVER_REPO=${DRIVER_REPO:-graphics-drivers}
NVIDIA_REPO=false

while getopts "hdvn:r:s" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install proprietary nvidia drivers but not cuda
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

if  ! in_os linux
then
    log_verbose linux only
    exit
fi

if ! has_nvidia
then
    log_exit "No NVIDIA adapter found with lspci"
fi

log_verbose checking for nouveau
if lsmod | grep nouveau
then
    log_warning "nouveau already still installed but nvidia drivers should remove"
    log_warning "if still there run  sudo apt-get remove xserver-xorg-video-nouveau"

fi

log_verbose determine nVidia product type and best driver
# https://askubuntu.com/questions/524242/how-to-find-out-which-nvidia-gpu-i-have
sudo update-pciids

log_verbose model parsing from lspci make sure to get only digits
# https://stackoverflow.com/questions/16618371/using-awk-to-grab-only-numbers-from-a-string
CONFIG=$(lspci | grep -m 1 "VGA.*NVIDIA")
log_verbose got nvidia configuration $CONFIG
if [[ $CONFIG =~ "GTX TITAN X" ]]
then
    MODEL=${MODEL:-10}
else
    MODEL=${MODEL:-$(( $(echo $CONFIG | awk '{print $10+0}') / 100 ))}
fi

if (( $MODEL == 0 ))
then
    log_verbose could not parse lspci string assuming default
    MODEL=10
fi


if (( $MODEL < 6 || $MODEL > 10 ))
then
    log_exit "bad model number $MODEL"
fi

DRIVER_VERSION="${DRIVER_VERSION:-"${DRIVER_GTX[$MODEL]}"}"

log_verbose trying to install driver version $DRIVER_VERSION

if [ -e /proc/driver/nvidia/version ]
then
    INSTALLED_VERSION=$(sed -n 's/.*\sKernel Module\s\+\([0-9]\+\)\..*/\1/p' < /proc/driver/nvidia/version )
    if (( $INSTALLED_VERSION < $DRIVER_VERSION ))
    then
        log_verbose Uninstall version and rerun this script
        log_error 2 $INSTALLED_VERSION is older than desired version $DRIVER_VERSION
    fi
    log_exit "nvidia driver already installed version $INSTALLED_VERSION"
fi

if in_linux debian
then
    # https://wiki.debian.org/NvidiaGraphicsDrivers#nvidia-detect
    # https://linuxconfig.org/how-to-install-the-latest-nvidia-drivers-on-debian-9-stretch-linux
    log_verbose Debian installation adding non-free repos ignoring specific versions
    "$SCRIPT_DIR/install-nonfree.sh"
    log_verbose Adding 32-bit repo support debian says not needed
    # sudo dpkg --add-architecture i386
    package_install nvidia-detect
    # with multiple cards just take the first driver recommendation
    DRIVER=$(nvidia-detect | grep -m 1 -o "nvidia.*-driver")
    log_verbose nvidia-driver says install $DRIVER
    log_verbose installing proprietary nvidia driver
    package_install firmware-linux $DRIVER  nvidia-settings nvidia-xconfig
    # installation of cuda happens in install-cuda.sh
    # nvidia-cuda-toolkit
    log_verbose creating X configuration file
    sudo nvidia-xconfig

    log_verbose debian does not load nvidia_uvm by default
    if in_linux debian
    then
        mod_install nvidia_uvm
    fi

fi

if in_linux ubuntu
then
    # http://stackoverflow.com/questions/13125714/how-to-get-the-nvidia-driver-version-from-the-command-line
    if [[ ! -e /proc/driver/nvidia/version ]] || ! grep -q "$DRIVER_VERSION" /proc/driver/nvidia/version
    then

        # For 14.04 ubuntu need the special repo
        if linux_version 14
        then
            NVIDIA_REPO=false
        fi
        # Switch to new Ubuntu blessed nvidia driver repo $NVIDIA_REPO set
        # http://www.omgubuntu.co.uk/2015/08/ubuntu-nvidia-graphics-drivers-ppa-is-ready-for-action
        # note we are using ls to do a wild card search
        # http://stackoverflow.com/questions/6363441/check-if-a-file-exists-with-wildcard-in-shell-script

        if $NVIDIA_REPO && ! ls /etc/apt/sources.list.d/$DRIVER_REPO-ppa* >/dev/null 1>&1
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
        fi

    fi

    log_verbose load the kernel stack if needed
    package_install nvidia-modprobe
    if nvidia-modprobe -u
    then
        nvidia-modprobe -c 255 -c 0 -c 1 -c 2 -c 3 -c 4 -c 5 -c 6 -c 7
    fi

    # https://www.gpugrid.net/forum_thread.php?id=2925
    # 4 (thermal monitor page will allow configuration of GPU fan speed)
    # 8 (allows setting per-clock domain and per-performance level offsets to apply to clock values)
    # 16 (the nvidia-settings command line interface allows setting GPU overvoltage)
    # note that nvidia-xconfig seems to create a xorg.conf file, but the new way is
    # creating a separate file in xorg.conf.d
    log_verbose enable overclocking with CoolBits
    sudo nvidia-xconfig --cool-bits=28


    log_warning if installlation of nvidia fails then you will not be able to login
        log_warning to debug sart a terminal session with CTRL-ALT-5 for tty5 or
        log_warning of CTRL-ALT-6 to start a session at tty6 and look at
        log_warning /var/log/syslog. You can also try $SCRIPT_DIR/remove_nvidia.sh
        log_warning but this does not work at least for Debian 9
        log_warning only complete reinstall is known to work
