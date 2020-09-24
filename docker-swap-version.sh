#!/usr/bin/env bash
##
## Swaps Docker for Mac edge vs stable release
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
DRYRUN="${DRYRUN:-false}"
while getopts "hdvn" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Edge or Stable release of docker, the default is to swap
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
           -n show the commands you would run (default: $DRYRUN)

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
        n)
            DRYRUN=true
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh


if ! in_os mac
then
    log_exit Mac only
fi

if is_package_installed docker
then
    log_verbose docker is installed so remove it
    package_uninstall docker
    log_verbose install docker edge
    # docker-edge is now in homebrew
    # tap_install caskroom/versions
    package_install docker-edge
    log_exit Docker Edge installed
fi

log_verbose uninstall docker-edge if present
package_uninstall docker-edge || true
log_verbose installing docker stable
package_install docker
log_exit Docker stable installed
