#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## Comment out crontab jobs
##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# over kill for a single flag to debug, but good practice
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME installs a crontab job to run the scons pre build
            echo flags: -d debug, -h help, -v verbose
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;&
        v)
            VERBOSE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# assumes all after the added by goes away
crontab -l  | \
    sed -n "/^# Added by install-crontab/q;p" | \
    crontab
