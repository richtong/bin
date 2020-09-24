#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## remove a standard set of users
##
##@author Rich Tong
##@returns 0 on success
##
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Remove test users for testing install-users.sh
            echo flags: -d debug, -h help, -v verbose
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

# remove accounts last
for script in remove-prebuild.sh remove-agents.sh remove-accounts.sh
do
    if ! "$SCRIPT_DIR/$script" $@
    then
        >&2 echo $SCRIPTNAME: error $? in $script
    fi
done
