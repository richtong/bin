#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Start vpn to surround.io
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# over kill for a single flag to debug, but good practice
OPTIND=1
VPN_CONNECTION=${VPN_CONNECTION:-"$HOME/vpn/surround.tblk"}
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME starts a vpn connection"
		echo flags: -d debug, -h help, -v verbose
		echo "connection tunnelblk file default: $VPN_CONNECTION"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;&
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
# Get to positional parameters
shift "$((OPTIND - 1))"

VPN_CONNECTION=${1:-"$VPN_CONNECTION"}
VPN_SUBNET=${VPN_SUBNET:-"10.0"}

if ip route | grep default | cut -d' ' -f 3 | grep -q "$VPN_SUBNET"; then
	echo "$SCRIPTNAME: Warning your local network conflicts with the surround.io"
	echo "corporate network currently at $VPN_SUBNET.*.*h"
	echo
	echo If you are using VMware, switch to NAT mode. If you are using a real
	echo "machine then you must change your private network out of that range"
	exit 1
fi

if pgrep openvpn >/dev/null; then
	log_error 3 "$SCRIPTNAME: openvpn running, kill with sudo pkill openvpn"
fi

if [[ ! -d $VPN_CONNECTION ]]; then
	log_error 4 "$SCRIPTNAME: $VPN_CONNECTION does not exist"
fi

if ! cd "$VPN_CONNECTION"; then
	log_error 5 "no $VPN_CONNECTION"
fi
conf=$(find ./*.conf | tail -1)
if [[ -z $conf ]]; then
	log_error 6 "No OpenVPN .conf file exist"
fi
sudo openvpn "$conf" &
