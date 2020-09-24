#!/usr/bin/env bash
##
## Installs the minikubes environment
## Assumes that kubectl is installed
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
            echo $SCRIPTNAME: Install Minikubes version of Kubernetes
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
source_lib lib-install.sh lib-util.sh
set -u
shift $((OPTIND-1))


KUBE_APP="${KUBE_APP:-minikube}"
KUBE_VER="${KUBE_RELEASE:-"v0.25"}"
if in_os mac
then
    # Deprecate this install, use brew cask install instead
    # KUBE_OS="${KUBE_OS:-darwin}"
    # KUBE_PROFILE="${KUBE_PROFILE:-"$HOME/.bash_profile"}"
    package_install minikube
    log_exit brew used to install minikube
fi

KUBE_OS="${KUBE_OATYPE:-linux}"
KUBE_PROFILE="${KUBE_PROFILE:-"$HOME/.bashrc"}"
KUBE_DEST="${KUBE_DEST:-"/usr/local/bin/$KUBE_APP"}"
KUBE_URL="${KUBE_URL:-"https://storage.googleapis.com/$KUBE_APP/releases/$KUBE_VER/$KUBE_APP-$KUBE_OS-amd64"}"

if command -v "$KUBE_APP"
then
    log_verbose "$KUBE_APP" already exists
    exit 0
fi

sudo curl -L "$KUBE_URL" -o "$KUBE_DEST"
sudo chmod +x "$KUBE_DEST"

KUBE_CKSUM="${KUBE_CKSUM:-"$(curl "$KUBE_URL.sha256")"}"
if [[ $(shasum -a 256 "$KUBE_DEST" | cut -d' ' -f1) != $KUBE_CKSUM ]]
then
    log_error 2 "Bad checksum for $KUBE_DEST"
fi
