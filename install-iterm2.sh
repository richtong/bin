#!/usr/bin/env bash
##
## Install iterm 2
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
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs iTerm2
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

source_lib lib-config.sh lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac
then
    log_exit "mac only"
fi

cask_install iterm2

log_verbose "install shell integrations"
curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash

if ! config_mark
then
    # shellcheck disable=SC2016
    config_add <<<-'EOF'
# shellcheck disable=SC2015,SC1090
[[ -e $HOME/.iterm2_shell_integration.bash ]] && source "$HOME/.iterm2_shell_integration.bash" || true
EOF
fi
