#!/usr/bin/env bash
##
## sets up the ssh-copy-id for public key login to remote machines
## the standard way which includes all authorized keys in the public-keys repo
## for the agent deploy
##

set -e && SCRIPTNAME="$(basename $0)"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
PUBLIC_KEYS=${PUBLIC_KEYS:-public-keys}
ORG_DOMAIN="${ORG_DOMAIN:-tongfamily.com}"
KEY=${KEY:-"$HOME/.ssh/$USER@$ORG_DOMAIN-$ORG_DOMAIN.id_ed25519"}
AUTHORIZED=${AUTHORIZED:-agent/deploy}
REMOTES=${REMOTES:-localremote}
while getopts "hdvk:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Sets the
            echo "flags: -d debug -v verbose"
            echo "       -k location of private key file (default: $KEY)"
            echo "       -a authorized for this user (default: $AUTHORIZED)"
            echo "note: the syntax is user|agent and then the name"
            echo "positionals: user@remote list to change (default: $REMOTES)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        k)
            KEY="$OPTARG"
            ;;
    esac
done
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh
shift $((OPTIND-1))
set -u


git_install_or_update "$PUBLIC_KEYS"

log_verbose install my personal key
if [[ ! -e $KEY ]]
then
    log_verbose no $KEY found
    exit 1
fi

authorized="$WS_DIR/git/$PUBLIC_KEYS/$AUTHORIZED/ssh/authorized_keys"
if [[ ! -e $authorized ]]
then
    log_warning no authorized_keys found at $authorized
fi

for remote in ${@:-$REMOTES}
do
    log_message trying $remote enter passphrase if needed

    if [[ -e "$authorized" ]]
    then
        # http://stackoverflow.com/questions/13650312/copy-and-append-files-to-a-remote-machine-cat-error
        log_verbose checking $remote for authorized_keys edits
        if ! ssh "$remote" "mkdir -p .ssh && touch .ssh/authorized_keys && grep -q \"Added by $SCRIPTNAME\" .ssh/authorized_keys"
        then
            log_verbose no edits found adding $authorized to $remote
            cat - "$authorized" <<<"# Added by $SCRIPTNAME from $HOSTNAME on $(date)"| \
                ssh "$remote" 'cat >>.ssh/authorized_keys'
        fi
    fi

    if [[ -e $KEY ]] && ! ssh-copy-id -i "$KEY" "$remote"
    then
        log_verbose got $? from ssh-copy-id of $KEY to $remote
        continue
    fi

done
