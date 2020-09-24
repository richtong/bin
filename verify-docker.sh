#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## verify docker
## @author rich
## @function verify-docker
## @return o if successful
#
# Run after docker installed as a test
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# over kill for a single flag to debug, but good practice
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $0 "flags: -d debug -f git-lfs file"
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

# now we can check for unbound variables
set -u

if ! docker run hello-world
then
    echo $SCRIPTNAME: docker did not install correctly
    exit 1
fi
