#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Start vpn to surround.io
##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# over kill for a single flag to debug, but good practice
OPTIND=1
VPN_CONNECTION=${VPN_CONNECTION:-"$HOME/vpn/surround.tblk"}
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME starts a vpn connection
            echo flags: -d debug, -h help, -v verbose
            echo connection tunnelblk file default: $VPN_CONNECTION
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;&
        v)
            VERBOSE=true
            ;;
        f)
            FORCE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
# Get to positional parameters
shift "$((OPTIND - 1))"

VPN_CONNECTION=${1:-"$VPN_CONNECTION"}
VPN_SUBNET=${VPN_SUBNET:-"10.0"}

if ip route | grep default | cut -d' ' -f 3 | grep -q "$VPN_SUBNET"
then
    echo $SCRIPTNAME: Warning your local network conflicts with the surround.io
    echo corporate network currently at $VPN_SUBNET.*.*h
    echo
    echo If you are using VMware, switch to NAT mode. If you are using a real
    echo machine then you must change your private network out of that range
        exit 1
    fi

    if pgrep openvpn > /dev/null
    then
        echo $SCRIPTNAME: openvpn running, kill with sudo pkill openvpn
        exit 3
    fi

    if [[ ! -d $VPN_CONNECTION ]]
    then
        echo $SCRIPTNAME: $VPN_CONNECTION does not exist
        exit 1
    fi

    cd "$VPN_CONNECTION"
    conf=$(ls *.conf | tail -1)
    if [[ -z $conf ]]
    then
        echo $SCRIPTNAME: No OpenVPN .conf file exist
        exit 1
    fi
    sudo openvpn "$conf" &
