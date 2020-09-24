#!/usr/bin/env bash
##
## install Pyenv to manage multiple python versions
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
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Pyenv to manage multiple python versions
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
source_lib lib-config.sh lib-install.sh lib-util.sh


if ! in_os mac
then
    log_exit "Mac only"
fi

log_verbose instaling pyenv
package_install pyenv

# https://opensource.com/article/19/5/python-3-default-mac
if ! config_mark
then
    log_verbose adding to profile
    config_add <<-"EOF"
command -v pyenv >/dev/null && eval "$(pyenv init  -)" || true
EOF
fi

log_warning updated $PROFILE to use source it
