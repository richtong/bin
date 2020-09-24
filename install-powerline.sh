#!/usr/bin/env bash
##
## install Powerline for neat looking status lines
## https://medium.com/@earlybyte/powerline-for-bash-6d3dd004f6fc
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
Installs Powerline
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
        *)
            echo "not flag -$opt"
            ;;
    esac
done
shift $((OPTIND-1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

pip_install powerline-status

location="$()pip show powerline-status | grep Location | awk '{print $2}'])"
log_verbose "powerline completion script at $location"

powerline="$location/powerline/bindings/bash/powerline.sh"
if [[ ! -e $powerline ]]
then
    log_error 2 "cannot fine powerline at $powerline"
fi

if ! config_mark "$(config_profile_shell)"
then
    config_add "$(config_profile_shell)" <<-EOF
[[ -r $powerline ]] && powerline-daemon -q && \
    export POWERLINE_BASH_CONTINUATION=1 && \
    export POWERLINE_BASH_SELECT=1 && \
    source "$powerline" || true


EOF
