#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
# Copies over the ssh and prebuild script needed for each agent
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"}

OPTIND=1
AGENTS=${AGENTS:-"build test deploy"}
SCRIPT_SSH_DIR=${SCRIPT_SSH_DIR:-"$HOME/prebuild/ssh"}
while getopts "hdvw:s:w:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Setup system to get git repos
            echo "flags: -d debug, -h help"
            echo "        -s ssh dir (default: $SCRIPT_SSH_DIR)"
            echo "        -w workspace"
            echo "list of agent accounts (default: '$AGENTS')"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        s)
            SCRIPT_SSH_DIR="$OPTARG"
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
    esac
done

# source after you know the debug switches
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-secret.ssh

GROUP=${GROUP:-"tongfamily"}
HOME_ROOT=${HOME_ROOT:-"$(readlink -f $HOME/..)"}
# now we can check for unbound variables
set -u
agent_install="$WS_DIR/git/user/agent/bin/install-dev-packages.sh"

# Note install.sh is sudo-less and can be run by agent
# install-dev-packages.sh needs sudo and must be run by a super user
log_verbose installing package prerequisites
if [[ -e "$agent_install" ]]
then
    log_verbose installing package prerequisites
    "$SHELL" "$agent_install"
fi


if [ ! -d "$SCRIPT_SSH_DIR" ]
then
    >&2 echo $SCRIPTNAME: No ssh directory $SCRIPT_SSH_DIR found
    exit 1
fi

log_verbose going through $AGENTS
for agent in $AGENTS
do
    log_verbose create $agent
    log_verbose creating mail
    if command -v sendmail
    then
        # create an email account for me at least
        # https://askubuntu.com/questions/350853/cannot-open-mailbox-var-mail-user-permission-denied-no-mail-for-user
        if ! groups "$agent" | grep -q '\bmail\b'
        then
            sudo adduser "$agent" mail
        fi
        # For whatever reason you have to create this file
        # http://ubuntuforums.org/showthread.php?t=1500892
        if sudo -u "$agent" [ ! -r "/var/mail/$agent" ]
        then
            # create a new mail file
            sudo install -D -b -o "$agent" -m 600 /dev/null "/var/mail/$agent"
        fi
    else
        >&2 echo $SCRIPTNAME: Warning no sendmail use install-ssmtp.sh to fix
    fi
    log_verbose create home directory
    sudo install -d -m 755 -o "$agent" -g "$GROUP" "$HOME_ROOT/$agent"

    pushd "$HOME_ROOT/$agent" > /dev/null



    log_verbose copy $SCRIPT_SSH_DIR/$agent to .ssh
    copy_ssh_dir "$agent" "$GROUP" "$SCRIPT_SSH_DIR/$agent" "$HOME_ROOT/$agent/.ssh"

    # put the agent mode script into it's home directory and needed libraries
    log_verbose creating $HOME_ROOT/$agent/{bin,lib}
    sudo install -d -m 755 -o "$agent" -g "$GROUP" bin lib
    sudo install -b -m 755 -o "$agent" -g "$GROUP" \
        "$SCRIPT_DIR/"{include.sh,install-agent.sh} bin
    # lib-keychain assumes the key names as # $agent@tongfamily.com-github.com.id_ed25519
    sudo install -b -m 644 -o "$agent" -g "$GROUP" \
        "$SOURCE_DIR/lib/"* lib

    # Note we need the -t for interactive terminal because there are passphrases requested
    # http://stackoverflow.com/questions/11372960/calling-an-interactive-bash-script-over-ssh
    # Turn off host checking dialog as we save a prompt and just going to
    log_verbose ssh into $agent@localhost to run install-agent.sh
    if !  ssh -t "$agent@localhost" \
        -o StrictHostKeyChecking=no \
        "bin/install-agent.sh $LOG_FLAGS"
    then
        log_verbose install-agent.sh returned $? typically because it has reset .bash_rc etc
        ssh -t "$agent@localhost" \
            "bin/install-agent.sh $LOG_FLAGS"
    fi

    popd >/dev/null

done
