#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
# Removes what was installed with install-agents.sh
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# over kill for a single flag to debug, but good practice
OPTIND=1
AGENTS=${AGENTS:-"build test deploy"}
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Reverse install-agents
            echo "flags: -d debug, -h help"
            echo "list of agent accounts (default: '$AGENTS')"
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

GROUP=${GROUP:-"tongfamily"}
HOME_DIR=${HOME_DIR:-"$(readlink -f $HOME/..)"}

# now we can check for unbound variables
set -u

shift $((OPTIND - 1))
if (( $# > 0 ))
then
    AGENTS="$@"
fi

remove() {
    if [[ -e $1 ]]
    then
        sudo mv "$1" "$1.bak"
    fi
}

log_verbose processing $AGENTS
for agent in $AGENTS
do
    log_verbose processsing $agent
    if groups "$agent" | grep -q '\bmail\b'
    then
        sudo deluser "$agent" mail || echo $SCRIPTNAME: could not remove $agent from mail group
    fi
    remove "/var/mail/$agent"

    if ! pushd "$HOME_DIR/$agent" >/dev/null
    then
        >&2 echo $SCRIPTNAME: $agent home directory does not exist
        continue
    fi

    # Too inconvenient to remoe the keys
    # remove .ssh

    remove install-agent.sh

    # Removes the .bashrc and other init script lines
    "$SCRIPT_DIR/remove-prebuild.sh" -s install-agent.sh "$HOME_DIR/$agent"

    # Removes any crontab's there

    log_verbose $agent reset repos to master and remove crontab
    ssh "$agent@localhost" \
        -o StrictHostKeyChecking=no \
        "ws/git/src/bin/remove-crontab.sh"

done
