#!/usr/bin/env bash
##
## install Norton Security from Comcast
## https://www.npmjs.com/package/onepass-cli for npm package
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
Installs Norton Security for the Mac
    usage: $SCRIPTNAME [ flags ]
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

if [[ $SCRIPT_DIR =~ /Volumes ]]
then
    source lib-git.sh lib-mac.sh lib-install.sh lib-util.sh
else
    source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh
fi


if ! in_os mac
then
    log_exit Only for the mac
fi
