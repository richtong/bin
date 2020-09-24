#!/usr/bin/env bash
##
##
## Retag a release
##
## This delete the local and global tags
## then repushes the current release
## Used for testing Github actions
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Push a release with the same tag as before
    usage: $SCRIPTNAME [ flags ] tags...
    flags: -d debug, -v verbose, -h help"
EOF
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            # add the -v which works for many commands
            export FLAGS+=" -v "
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

for tag in "$@"
do
    log_verbose delete $tag
    if ! git tag -d "$tag"
    then
        log_verbose no $tag on local
    fi
    log_verbose delete remote $tag
    if ! git push origin :"$tag"
    then
        log_verbose no remote $tag
    fi
    log_verbose commit new local $tag
    git tag -a "$tag" -m "Testing $tag"
    log_verbose push local to remote $tag
    git push origin "$tag"
done
