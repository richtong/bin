#!/bin/bash
##
## authorized keys of users into a single authorized_keys for automated accounts
## so that any user can access any of the automated agents
##
##@author Rich Tong
##@returns 0 on success
#
set -eu && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"}
KEY_DIR="${KEY_DIR:-public-keys}"
BOT_KEY_DIR="${BOT_KEY_DIR:-personal/rich/public-keys/agent}"
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Take all public keys and make an authorized one
            echo flags: -d debug, -v verbose, -h help
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
shift $((OPTIND-1))

agent_dir="$WS_DIR/git/$KEY_DIR/agent"
log_verbose updating agents in $agent_dir
mkdir -p "$agent_dir"
pushd "$agent_dir" > /dev/null
# fall through is no match
# https://www.cyberciti.biz/faq/bash-loop-over-file/
shopt -s nullglob
for BOT in *
do
    if [[ ! -d $BOT ]]
    then
        log_verbose $BOT is not a directory skipping
        continue
    fi
    log_verbose adding all user authorized keys to $BOT
    mkdir -p "$BOT/ssh"
    if [[ -e "$BOT/ssh/authorized_keys" ]]
    then
        rm "$BOT/ssh/authorized_keys"
    fi
    # All real users can access bot accounts
    cat ../user/*/ssh/authorized_keys >> "$BOT/ssh/authorized_keys"
    # Bots can access themselves
    cat "$WS_DIR/git/$BOT_KEY_DIR/$BOT/ssh/$BOT"*".pub" >> "$BOT/ssh/authorized_keys"
done

popd >/dev/null

log_message check $agent_dir and git commit when this looks correct
