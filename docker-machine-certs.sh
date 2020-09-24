#!/usr/bin/env bash
##
## install docker-machine certs and configurations
## https://gist.github.com/schickling/2c48da462a7def0a577e
## https://github.com/docker/machine/issues/2516
## https://github.com/docker/machine/issues/1328
##
##
## Because you need the same certificates to have multiple users access a
## docker-machine we link to them from the store
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

MACHINE_STORAGE_PATH=${MACHNE_STORAGE_PATH:-"$HOME/.docker/machine"}
FORCE=false
OPTIND=1
while getopts "hdvfs:p:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install docker-machine certs and config.json
            echo              assumes that you already have the certs in your Private store
            echo              and the config files are in the src repo
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -f force overwriting your certs to this machine"
            echo "       -s docker-machine storage path (default: $MACHINE_STORAGE_PATH)"
            echo "       -p your private key store"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        f)
            FORCE=true
            ;;
        s)
            MACHINE_STORAGE_PATH="$OPTARG"
            ;;
        p)
            PRIVATE="$OPTARG"
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-util.sh

if [[ -z $PRIVATE ]]
then
    if in_os mac
    then
        PRIVATE=/Volumes/Private
    else
        PRIVATE="$HOME/Private"
    fi
fi

set -u
shift $((OPTIND-1))

# We no longer use these just use certs and recreate
#log_verbose installing into docker-machine-import-export
#git_install_or_update "https://gist.github.com/schickling/2c48da462a7def0a577e" docker-machine-import-export

log_verbose assumes you have the private keys already
if [[ ! -e $PRIVATE/certs ]]
then
    log_error 2 "no docker-machine certs found at $PRIVATE/certs"
fi

mkdir -p "$MACHINE_STORAGE_PATH/certs"
log_verbose going through certificates in $PRIVATE/certs
pushd "$PRIVATE/certs" > /dev/null
# fall through is no match
# https://www.cyberciti.biz/faq/bash-loop-over-file/
shopt -s nullglob
for cert in *
do
    log_verbose trying $cert
    if $FORCE
    then
        log_verbose removing $cert
        rm -f "$MACHINE_STORAGE_PATH/certs/$cert"
    fi

    if [[ ! -e "$MACHINE_STORAGE_PATH/certs/$cert" ]]
    then
        log_verbose sym link $cert
        ln -s "$PRIVATE/certs/$cert" "$MACHINE_STORAGE_PATH/certs"
    fi
done
popd >/dev/null

log_verbose linked certificates, now use docker-machine create to use the shared certs
