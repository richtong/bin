#!/usr/bin/env bash
##
## Flux changes screen color on a mac
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $0 "flags: -d debug"
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
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-util.sh
set -u

if ! in_os mac
then
    log_error 1 only work on a Mac
fi

mac_download_and_move Flux.App https://justgetflux.com/mac/Flux.zip
