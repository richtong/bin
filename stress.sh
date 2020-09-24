#!/usr/bin/env bash
##
## Stress test a linux system
## http://www.cyberciti.biz/faq/stress-test-linux-unix-server-with-stress-ng/
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

TIMEOUT=${TIMEOUT:-360s}
OPTIND=1
while getopts "hdvt:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install 1Password
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -t timeout after (default: $TIMEOUT)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        t)
            TIMEOUT="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh
set -u
shift $((OPTIND-1))

if  [[ ! $OSTYPE =~ linux ]]
then
    log_verbose only on linux
    exit
fi

package_install stress

log_message start at $(uptime)
stress -c 4 -i 2 -m 2 -t "$TIMEOUT"
log_message end with $(uptime)
