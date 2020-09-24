#!/usr/bin/env zsh
##
## Install zsh utilities
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
# https://stackoverflow.com/questions/9901210/bash-source0-equivalent-in-zsh#23259585
# The below works for bash or zsh, checks for bash_source first
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]:-${(%):-%x}}")"
# set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
# SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
VERSION="${VERSION:-7}"
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs zsh utilities
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
EOF
            exit 0
            ;;
        d)
            export DEBUGGING=true
        ;; v)
            export VERBOSE=true
            # add the -v which works for many commands
            # export must be a simple variable in zsh
            # https://unix.stackexchange.com/questions/111225/local-variables-in-zsh-what-is-the-equivalent-of-bashs-export-n-in-zsh#111227
            FLAGS+=" -v "
            export FLAGS
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh

# https://ohmyz.sh
log_verbose install oh my zsh
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
compaudit 2>/dev/null | xargs chmod g-w,o-w
