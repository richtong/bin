#!/usr/bin/env bash
#
# If an ssh agent doesn't exist look for it and set it
# This should be sourced
#
##
##@author Rich Tong
##@returns 0 on success
#
# If this is run as part of ssh login then there is no SCRIPTNAME or SCRIPT_DIR
# yet as we have not logged into the system and we cannot find WSDIR
# So do not use $0 for SCRIPTNAME as BASH_SOURCE[0] is correct
#
set -e && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: adds the standard groups for our corporate machines
            echo "flags: -d debug, -h help -v verbose"
            echo "run this as \`eval $SCRIPTNAME\` to set up ssh-agent"
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

# if it non zero just continue remember this is sourced so do not exit
if [[ -z $SSH_AUTH_SOCK ]]
then
    log_verbose look for the OS X variant
    if [[ -e /private/tmp ]]
    then
        TMP=${TMP:-/private/tmp}
        NAME=${NAME:-Listeners}
elif [[ -e /tmp ]]
    then
        TMP=${TMP:-/tmp}
        NAME=${NAME:agent.*}
    fi

    SSH_AUTH_SOCK=$(sudo find "$TMP" -type s -name "$NAME")
    log_verbose found socker $SSH_AUTH_SOCK

    if [[ -n $SSH_AUTH_SOCK ]]
    then
        # found it and run the export
        export SSH_AUTH_SOCK
    fi

fi
