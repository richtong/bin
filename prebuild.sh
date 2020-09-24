#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## bootstrap to install.sh
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

ORG_NAME="${ORG_NAME:-tongfamily}"
ORG_DOMAIN="${ORG_NAME:-$ORG_NAME.com}"
export DOCKER_USER=${DOCKER_USER:-"$ORG_NAME$USER"}
export MAIN_EMAIL=${MAIN_EMAIL:-"$USER@ORG_DOMAIN"}
export GIT_USER=${GIT_USER:-"$ORG_NAEM-$USER"}
export GIT_EMAIL=${GIT_EMAIL:-"$USER@$ORG_DOMAIN"}
OPTIND=1
while getopts "hdvu:e:r:m:w:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install 1Password
            echo flags: -d debug, -h help
            echo "       -r dockeR user name (default: $DOCKER_USER)"
            echo "       -m mail for local or docker use (default: $MAIN_EMAIL)"
            echo "       -u username for git (default: $GIT_USER)"
            echo "       -e email for git (default: $GIT_EMAIL)"
            echo "       -w workspace directory"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        u)
            GIT_USER="$OPTARG"
            ;;
        e)
            GIT_EMAIL="$OPTARG"
            ;;
        r)
            DOCKER_USER="$OPTARG"
            ;;
        m)
            MAIN_EMAIL="$OPTARG"
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

set -u

if [[ $USER == rich ]]
then
    ./install-1password.sh
fi

if [[ ! $OSTYPE =~ darwin ]] && ! command -v git
then
    apt-get install -y git
fi

if [[ ! -e "$SOURCE_DIR" ]]
then
    mkdir -p "$WSDIR/git"
    cd "$WSDIR/git"
    git clone https://github.com/$ORG_DOMAIN/src
fi

"$SOURCE_DIR/bin/install.sh" -u "$GIT_USER" -e "GIT_EMAIL" -r "$DOCKER_USER" -m "$MAIN_EMAIL"
