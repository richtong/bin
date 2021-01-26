#!/usr/bin/env bash
##
## install Raspbian from Mac
##
##@author Rich Tong
##@returns 0 on success
# https://www.raspberrypi.org/documentation/installation/installing-images/mac.md
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
SD_WRITE="${SD_WRITE:-false}"
SSID="${SSID:-guest}"
PSK="${SSID:-guest}"
RPI_OS="${RPI_OS:-https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-01-12/2021-01-11-raspios-buster-armhf-lite.zip}"
RPI_SHA256="${RPI_SHA256:-d49d6fab1b8e533f7efc40416e98ec16019b9c034bc89c59b83d0921c2aefeef}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvs:wo:i:p:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Raspberry Pi OS from Mac
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
           -s SD location (default: the last physical external drive in /dev/disk or set $SD_LOC)
           -w run the command to write (default: $SD_WRITE)
           -o the location of the Raspberry Pi OS image (default: $RPI_OS)
           -i Wifi SSID (default: $SSID)
           -p Wifi PSK password (default: $PSK)
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
        s)
            SD_LOC="$OPTARG"
            ;;
        w)
            SD_WRITE=true
            ;;
        o)
            RPI_OS="$OPT_ARG"
            ;;
        i)
            SSID="$OPT_ARG"
            ;;
        p)
            PSK="$OPT_ARG"
            ;;
        *)
            echo "not flag -$opt"
            ;;
    esac
done
shift $((OPTIND-1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac
then
  log_verbose "Not Mac"
fi

if [[ ! -v SD_LOC ]]
then
    # https://github.com/koalaman/shellcheck/wiki/SC2206
    # This does not work with std pipe not sure why
    # diskutil list | grep '(external, physical)' | awk '{print $1}' | mapfile -t possible_disks
    possible_disks=$(diskutil list | grep '(external, physical)' | awk '{print $1}')
    # https://github.com/koalaman/shellcheck/wiki/SC2206
    mapfile -t possible_disks_array <<<"$possible_disks"
    log_verbose "possible physical external disks that may be SD cards ${possible_disks_array[*]}"
    SD_LOC="${possible_disks_array[-1]}"
    log_warning "guessing that it is the last disk $SD_LOC if in correct set -fs /dev/diskn correctly"
fi

if ! diskutil info "$SD_LOC" | grep "Card Reader"
then
    log_warning "$SD_LOC not an SD Card Reader check before running -f"
fi

log_verbose "Assuming SD is at $SD_LOC"

# https://osxdaily.com/2009/12/01/list-all-mounted-drives-and-their-partitions-from-the-terminal/
if df | grep "^$SD_LOC"
then
    log_verbose "$SD_LOC appears to be mounted attempt unmount"
    diskutil unmountDisk "$SD_LOC"
fi

# try to download Raspberry Pi OS""
log_verbose "downloading from $RPI_OS"
download_url_open "$RPI_OS"
RPI_OS_FILE="$WS_DIR/cache/$(basename "${RPI_OS%.*}").img"

if [[ ! -e $RPI_OS_FILE ]]
then
    log_error 1 "No $RPI_OS_FILE exists"
fi

# https://unixutils.com/string-manipulation-with-bash/
# Need backslash for all the slashes in bash substitute
SD_LOC_RAW="${SD_LOC/#\/disk\/disk/\/dev\/rdisk/}"
log_verbose "would run running dd bs=1M if=$RPI_OS_FILE of=$SD_LOC_RAW"
if $SD_WRITE
then
    log_verbose "Force enabled, running command"
    sudo dd bs=1M if="$RPI_OS_FILE" of="$SD_LOC_RAW"
    # https://www.computerhope.com/unix/sync.htm
    sync
fi

log_verbose mounting "$SD_LOC"
diskutil mountDisk "$SD_LOC"

# note that Raspberry Pi OS adds a Unicode #2068 which is a first strong
# isolate for bidi languages so we need to get rid of this in the first and
# last
# https://fabianlee.org/2020/11/18/bash-fixing-an-ascii-text-file-changed-with-unicode-character-sequences/
SD_MOUNT="/Volumes/$(diskutil list "$SD_LOC" | grep FAT_32 | awk '{print $3}' | iconv -f UTF-8 -t ASCII//IGNORE)"
log_verbose "guessing the boot volume $SD_MOUNT"
if [[ ! -d $SD_MOUNT ]]
then
    log_error 2 "Could not find mount point $SD_MOUNT do you need to write the SD Drive"
fi

log_verbose now install the wifi configuration first touch 
# https://www.teknotut.com/en/install-raspberry-pi-headless-from-mac-and-windows/
log_verbose "creating $SD_MOUNT/ssh"
touch "$SD_MOUNT/ssh"
if [[ ! -e $SD_MOUNT/wpa_supplicant.conf ]]
then
    log_verbose "creating $SD_MOUNT/wpa_supplicant.conf"
    cat > "$SD_MOUNT/wpa_supplicant.conf" <<-EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=ID

network={
    ssid="$SSID"
    psk="$PSK"
    key_mgmt=WPA-PSK
}
EOF
fi

log_verbose "Check the SD and then run diskutil unmountDisk $SD_LOC"
log_verbose "Insert SD into the Raspberry Pi and it should connect to the network"
log_verbose "default computer name is raspbberrypi.local"
log_verbose "default user name is pi"
log_verbose "default password is raspberry"
