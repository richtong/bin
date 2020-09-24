#!/usr/bin/env bash
##
## Installs Kubernetes both the kubectl
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
            echo $SCRIPTNAME: Install Kubernetes
            echo "flags: -d debug, -v verbose, -h help"
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
shift $((OPTIND-1))
source_lib lib-util.sh
KUBE_VERSION="${KUBE_RELEASE:-"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"}"
KUBE_DEST="${KUBE_DEST:-"/usr/local/bin/kubectl"}"
KUBE_URL="${KUBE_URL:-https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl}"

log_warning kubectl is no longer needed, kubernetes is included in docker

if command -v kubectl
then
    log_verbose "already installed"
    exit 0
fi

if in_os mac
then
    "$SCRIPT_DIR/install-brew-cask.sh" kubectl
    KUBE_PROFILE="${KUBE_PROFILE:-"$HOME/.bash_profile"}"
else
    log_verbose curl from $KUBE_URL
    sudo curl -L "$KUBE_URL" -o "$KUBE_DEST"
    sudo chmod +x "$KUBE_DEST"
    KUBE_PROFILE="${KUBE_PROFILE:-"$HOME/.bashrc"}"
fi

log_verbose installing bash autocomplete
if ! grep "Added by $SCRIPTNAME" "$KUBE_PROFILE"
then
    echo "# Added by $SCRIPTNAME on $(date)" >>"$KUBE_PROFILE"
    echo 'source <(kubectl completion bash)' >>"$KUBE_PROFILE"
fi
log_message source $KUBE_PROFILE to get autocompletions or logoff and log back on
