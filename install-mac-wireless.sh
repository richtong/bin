#!/usr/bin/env bash
##
## command for manipulating mac wireless
##
## Moves secrets into a usb or a Dropbox
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
AIRPORT=${AIRPORT:-"/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"}
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: commands for Mac wireless"
		echo flags: -d debug -v verbose
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND - 1))

if [[ $(uname) != Darwin ]]; then
	echo "$SCRIPTNAME: only runs on a mac"
	exit 0
fi

# http://stackoverflow.com/questions/4481005/get-wireless-ssid-through-shell-script-on-mac-os-x

log_verbose current wifi connection information
"$AIRPORT" -I
networksetup -getairportnetwork en1
system_profiler SPAIRPortDataType

# http://osxdaily.com/2012/02/28/find-scan-wireless-networks-from-the-command-line-in-mac-os-x/

log_verbose scan for wifi networks
"$AIRPORT" -s

log_verbose disconnect network
"$AIRPORT" -x

log_verbose change network to channel
read -rp "new channel? " CHANNEL
"$AIRPORT" -c "$CHANNEL"

log_verbose connecto to a spectific network

read -rp "SSID? " SSID
read -rp "PASSOWRD? " PASSWORD
networksetup -setairportnetwork Airport "$SSID" "$PASSWORD"

# http://www.cnet.com/news/how-to-adjust-network-settings-in-os-x-via-the-command-line/
log_verbose networks on this machine x
networksetup -listnetworkserviceorder
networksetup -getairportpower en0
networksetup -setairportpower en0 off
networksetup -setairportpower en0 on

Log_verbose list all networks
networksetup -listpreferredwirelessnetworks en1
while read -rp "remove a network? " NETWORK; do
	networksetup -removerpreferredwirelessnetwork en1 "$NETWORK"
done
networksetup -removerpreferredwirelessnetowrk
