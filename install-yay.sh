#!/usr/bin/env bash
##
## Installs yay a simple yaml parser for bash
## It does require two spaces for indents and is not general
## https://raw.githubusercontent.com/johnlane/random-toolbox/master/usr/lib/yay
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install 1Password
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

#
mkdir -p "$SOURCE_DIR/lib"
pushd "$SOURCE_DIR/lib" > /dev/null
curl -O L https://raw.githubusercontent.com/johnlane/random-toolbox/master/usr/lib/yay
chmod +x yay
popd >/dev/null
