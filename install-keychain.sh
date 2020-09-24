#!/usr/bin/env bash
##
## installs keys and the right keychain
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
            echo $SCRIPTNAME: Install correct keychain and list of keys
            echo "flags: -d debug, -v verbose, -h help"
            echo "positional: list of keys"
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
source_lib lib-keychain.sh

ORG_DOMAIN="${ORG_DOMAIN:-tongfamily.com}"

set -u
shift $((OPTIND-1))

if (( $# == 0 ))
then
    KEYS="$HOME/.ssh/$USER@$ORG_DOMAIN-github.com.id_ed25519 "
else
    # https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
    KEYS="$@"
fi

log_verbose using keys $KEYS
log_verbose ssh agent is $(env | grep SSH)
if ! use_openssh_keychain $KEYS
then
    echo reboot needed then rerung
    fi
