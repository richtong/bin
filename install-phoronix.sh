#!/usr/bin/env bash
##
## Run phoronix tests
## http://dustymabe.com/2012/12/30/running-benchmarks-with-the-phoronix-test-suite/
## See https://openbenchmarking.org/ for list of popular tests
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
VERSION=${VERSION:-7.2.1}
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install Phoronix Test Suite
            echo "flags: -d debug, -v verbose -h help"
            echo "       -r version to load (default: $VERSION)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        r)
            RELEASE="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

shift $((OPTIND-1))

set -u

if ! in_os linux
then
    log_error 1 "only runs on linux"
fi

log_verbose installing phoronix

if in_linux ubuntu
then
    package_install phoronix-test-suite
else
    deb_install phoronix-test-suite "http://phoronix-test-suite.com/releases/repo/pts.debian/files/phoronix-test-suite_$RELEASE_all.deb"
fi
