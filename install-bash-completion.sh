#!/usr/bin/env bash
##
## Install bash completions on Mac
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
$SCRIPTNAME: Install bask completion
flags: -d debug, -v verbose, -h help
EOF
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            ;;
        *)
            echo "no flag -$opt"
            ;;
    esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh lib-config.sh
shift $((OPTIND-1))

log_verbose attempt update install
package_install bash-completion
# http://davidalger.com/development/bash-completion-on-os-x-with-brew/
# this is now deprecated as of Aug 2017
#if brew list bash-completion > /dev/null
#then
#    log_verbose install additional completions
#    brew tap homebrew/completions
#fi
PROFILE="${PROFILE:-"HOME/.bashrc"}"
log_verbose "install in the non-login shell profile so it completion always runs"

if ! config_mark "$PROFILE"
then
    log_verbose "adding bash_completion to $(config_profile)"
    # We need to quote this since it is going into the profile
    # shellcheck disable=SC2016
    config_add "$PROFILE"<<<'source "$(brew --prefix)/etc/bash_completion"'
fi
