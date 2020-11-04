#!/usr/bin/env bash
##
## install machines with accounts for testing etc
## Deprecated with the use of Jenkins and iam-keys
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

ACCOUNTS=${ACCOUNTS:-false}
TESTING_MACHINE=${TESTING_MACHINE:-false}
DEPLOYMENT_MACHINE=${$DEPLOYMENT_MACHINE:-false}
OPTIND=1
while getopts "hdvatx" opt
do
    case "$opt" in
        h)
            echo "$SCRIPTNAME: Install machines"
            echo "flags: -d debug, -v verbose, -h help"
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            ;;
        a)
            ACCOUNTS=true
            ;;
        t)
            TESTING_MACHINE=true
            ;;
        x)
            DEPLOYMENT_MACHINE=true
            ;;
        *)
            echo "no -$opt" >&2
            ;;
    esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if ! in_os linux
then
    log_exit "only linux"
fi

log_verbose Create account and agent configs deprecated use iam-keys instead
if $ACCOUNTS
then
    log_verbose "install-accounts puts in all accounts"
    "$SHELL" "$SOURCE_DIR/bin/install-accounts.sh"
    log_verbose install-agents.sh creates all agent configs
    "$SHELL" "$SOURCE_DIR/bin/install-agents.sh"
fi

install_crontab() {
    if [[ -z $1 ]]; then return; fi
    log_verbose "create automated $1 agent"
    # Assume default location is ~/ws in the agent directory
    # Also defeat the check since we are on localhost
    # shellcheck disable=SC2086
    ssh -o StrictHostKeyChecking=no \
        "$1@localhost" \
        ws/git/src/bin/install-crontab.sh $LOG_FLAGS
}

# Enable crontab and start running agents
if $DEPLOY_MACHINE
then
    install_crontab deploy
fi

if $TESTING_MACHINE
then
    install_crontab build
    install_crontab test
fi
