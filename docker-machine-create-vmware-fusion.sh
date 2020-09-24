#!/usr/bin/env bash
##
## Recreate the Mac VMware Fusion box for running apps
## Need this because xhyve in docker for mac is not working
## or well supported as of September 2017
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

MACHINE=${MACHINE:-fusion}
OPTIND=1
while getopts "hdvm:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Create default VMware Fusion for the Mac
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -m name of the machine (default: $MACHINE)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        m)
            MACHINE="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if ! in_os mac
then
    log_error 1 only runs on Mac
fi

if docker-machine status "$MACHINE"
then
    if docker-machine status "$MACHINE" | grep Running
    then
        docker-machine stop "$MACHINE"
    fi
    docker-machine rm -f "$MACHINE"
fi

docker-machine create -d vmwarefusion --vmwarefusion-cpu-count "4" \
    --vmwarefusion-disk-size "100000" --vmwarefusion-memory-size "4096" "$MACHINE"

docker login

echo $MACHINE created, to use run the command
echo eval '$('docker-machine env $MACHINE')'
