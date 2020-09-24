#!/usr/bin/env bash
##
## Temporarilty run vino
## http://askubuntu.com/questions/304017/how-to-set-up-remote-desktop-sharing-through-ssh
## http://askubuntu.com/questions/4474/enable-remote-vnc-from-the-commandline
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install VNC Server
            echo "flags: -d debug, -v verbose, -h help"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND-1))


if [[ $OSTYPE =~ darwin ]]
then
    log_verbose only for Linux
    exit
fi


# get_env variable [user] [gui]
# gui is nautilus for ubuntu
#        gnome for others
get_env() {
    if (($# < 1 )); then return; fi
    local variable="$1"
    local user="${2:-"$USER"}"
    local gui="${3:-nautilus}"
    local pid=$(pgrep -u "$user" "$gui" | head -1)
    echo $(grep -z "$variable" "/proc/$pid/environ" | cut -d= -f2-)
}

# http://stackoverflow.com/questions/23415117/shell-script-with-export-command-and-notify-send-via-crontab-not-working-export
if [[ -z $DBUS_SESSION_BUS_ADDRESS ]]
then
    log_verbose looking for active gnome seeion and its DBUS for user $USER
    export DBUS_SESSION_BUS_ADDRESS="$(get_env DBUS_SESSION_BUS_ADDRESS)"
    log_verbose found $DBUS_SESSION_BUS_ADDRESS
fi

if [[ -z $DISPLAY ]]
then
    log_verbose looking for active display for user $USER
    export DISPLAY="$(get_env DISPLAY)"
fi

if pgrep vino > /dev/null
then
    pkill vino
fi
gsettings set org.gnome.Vino enabled true
gsettings set org.gnome.Vino prompt-enabled false
gsettings set org.gnome.Vino require-encryption false
/usr/lib/vino/vino-server &
