#!/usr/bin/env bash
##
## Create a machine learning instance with vmware fusion
##
## Moves secrets into a usb or a Dropbox
##
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
MACHINE=${MACHINE:-ml}
while getopts "hdvurp:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: create a vmware fusion machine with machine learning in it
            echo flags: -d debug -v verbose
            echo "       -m name of machine learning machine"
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

if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND-1))

if [[ $(uname) != Darwin ]]
then
    echo $SCRIPTNAME: only runs on a mac
    exit 0
fi

if ! docker-machine status "$MACHINE" > /dev/null
then
    docker-machine create --driver vmwarefusion \
        --vmwarefusion-cpu-count 4 \
        --vmwarefusion-disk-size 100000 \
        --vmwarefusion-memory-size 4096 \
        "$MACHINE"
fi

if ! docker-machine status "$MACHINE" | fgrep Running >/dev/null
then
    docker-machine start "$MACHINE"
fi

echo to access the machine \'$MACHINE\' run
echo "    \`docker-machine env $MACHINE\`"
echo Note that the docker machine does not appear in the vmware fusion app
echo To access it you should run
echo "     docker-machine ssh $MACHINE"
