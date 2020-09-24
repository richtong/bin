#!/usr/bin/env bash
##
## set graphical mode or consolt mode designed for ubuntu 16.04
## https://askubuntu.com/questions/800239/how-to-disable-lightdmdisplay-manager-on-ubuntu-16-0-4-ltsv
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
MODE="${MODE:-console}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo Switch between consoler and graphical mode
            echo usage: $SCRIPTNAME [ flags ] [ positionals...]
            echo
            echo "flags: -d debug, -v verbose, -h help"
            echo
            echo "positionals: multi-user | graphical"
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
source_lib lib-util.sh lib-config.sh
shift $((OPTIND-1))

# set mode to first argument take the default if $1 not supplied
MODE="${1:-"$MODE"}"

if [[ ! $OSTYPE =~ linux ]]
then
    log_exit linux only
fi

if ! is_linux ubuntu ||  [[ ! $(linux_version) =~ ^16 ]]
then
    log_exit Ubuntu 16.x onluy
fi

current_mode=$(sudo systemctl get-default)
log_verbose set-default currently set to $current_mode
case "$MODE" in
    m*)
        MODE=multi-user
        ;;
    g*)
        MODE=graphical
        ;;
    f*)
        log_verbose flipping to other mode
        if [[ $current_mode =~ ^g ]]
        then
            MODE=multi-user
        else
            MODE=graphical
        fi
        ;;
esac

sudo systemctl set-default $MODE.target
log_verbose set-default currently set to $MODE

# https://www.howtoforge.com/tutorial/grub-2-boot-loader-menu-and-splash-screen-image/
set_config_var GRUB_CMDLINE_LINUX_DEFAULT '"quiet"' /etc/default/grub

log_verbose remove splash from /etc/default/grub
sudo update-grub

log_verbose to start graphical when in a console
log_verbose surn sudo systemctl start lightdm.service

log_assert "[[ $MODE.target == $(sudo systemctl get-default) =~ graphical.target ]]" \
    "systemctl get-default matched $MODE"
