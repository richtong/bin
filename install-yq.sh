#!/usr/bin/env bash
##
## install yq and command completion
## https://mikefarah.gitbook.io/yq
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
Installs 1Password
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

source_lib lib-install.sh lib-config.sh lib-util.sh


if ! in_os mac
then
    log_exit "mac only"
fi

log_verbose "installing yq"
package_install yq
hash -r

if ! config_mark; then
    log_verbose "installing command completion into $(config_profile)"
    config_add <<-EOF
# shellcheck disable=SC1090
source <(yq shell-completion bash)
EOF
fi
