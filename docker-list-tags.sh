#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##install 1password for linux
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvw:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: List remote tags from a docker public registry
            echo flags: -d debug, -h help
            echo "      repo/image repo/image repo/image..."
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
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for item in "$@"
do
    curl --silent "https://registry.hub.docker.com/v2/repositories/$item/tags/" | jq -c '.results[]["name"]'
done
