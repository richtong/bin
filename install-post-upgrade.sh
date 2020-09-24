#!/usr/bin/env bash
##
## Post installation a major MacOS upgrade
## Big things that break are osx fuse with catalina
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
VERSION="${VERSION:-7}"
INCOMPATIBLE_CASKS="${INCOMPATIBLE_CASKS:-"osxfuse"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvi:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Post installation after a major OSX upgrade
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
           -i incompatible casks (default: $INCOMPATIBLE_CASKS)
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
        i)
            INCOMPATIBLE_CASKS="$OPTARG"
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh


if ! in_os mac
then
    log_exit "Mac only"
fi

log_verbose upgrade brew and all casks
brew update
brew upgrade

log_verbose now reinstall incompatibles
for c in $INCOMPATIBLE_CASKS
do
    brew cask reinstall $INCOMPATIBLE_CASKS
done

if ! brew cask upgrade
log_verbose brew cask failed with $?
fi

log_warning you should now reboot
