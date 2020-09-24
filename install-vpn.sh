#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install openvpn and configuration to connect to surround.io network
## assumes the client key names are the same as $USER
## Users the Tunnelblick format to keep the config and keys together
## https://tunnelblick.net/cConfigT.html#files-contained-in-a-tunnelblick-vpn-configuration
## Also makes it easy to use for the Mac OpenVPN client Tunnelblick ##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvk:u:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME installs vpn configuration files for surround.io corpnet
            echo flags: -d debug, -h help, -v verbose
            echo "     -k Directory where keys are kept"
            echo "     -u User name of the new vpn user"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;&
        v)
            VERBOSE=true
            ;;
        k)
            KEY_DIR="$OPTARG"
            ;;
        u)
            KEY_USER="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# must change if this file moves relative to ws
KEY_DIR=${KEY_DIR:-"$HOME/surround.tblk"}
KEY_USER=${KEY_USER:-"$USER"}

set -u
# move positional parameters into place
shift "$((OPTIND - 1))"

# easy-rsa needed to generate your own keys
# https://help.ubuntu.com/lts/serverguide/openvpn.html
# Get our own copy of easy-rsa although
# we still need the parameters from source
sudo apt-get install -y openvpn resolvconf easy-rsa

if [[ ! -e /etc/openvpn/easy-rsa ]]
then
    sudo mkdir -p /etc/openvpn/easy-rsa
    sudo rsync -a  /usr/share/easy-rsa/* /etc/openvpn/easy-rsa
fi

# Disable autostart of openvpn we want to manually start it
sudo update-rc.d openvpn disable

mkdir -p "$KEY_DIR"

# Check for the private keys
should_exit=false
for ext in crt csr key
do
    if [[ -z $KEY_DIR/$KEY_USER.$ext ]]
    then
        >&2 echo SCRIPTNAME: Invalid $KEY_DIR missing $KEY_USER.$ext
        should_exit=true
    fi
done
if "$should_exit"
then
    exit 1
fi

log_verbose $KEY_DIR/$KEY_USER.* files present

# copy ca.crt, ta.key and client.conf
for file in ca.crt ta.key
do
    if [[ ! -r $KEY_DIR/$file ]]
    then
        install -m 600 "$WS_DIR/git/src/infra/vpn/$file" "$KEY_DIR"
        log_verbose install $KEY_DIR/$file
    else
        log_verbose $file present
    fi
done

export KEY_DIR
export KEY_USER
envsubst < "$WS_DIR/git/src/infra/vpn/data/client.conf"  \
    > "$KEY_DIR/client.conf"

# Secure it all
chmod 600 "$KEY_DIR"/*
chmod 700 "$KEY_DIR"

echo $SCRIPTNAME:
echo to start: '(cd' $KEY_DIR '&& sudo openvpn client.conf) &'
echo to stop:  sudo pkill openvpn
