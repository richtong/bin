#!/usr/bin/env bash
##
## install jenv
## http://www.jenv.be
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
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Java environment
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
           -r version number (default: $VERSION)
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
        r)
            VERSION="$OPTARG"
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

brew_install jenv
if ! config_mark
then
    # this will fail if not yet installed so add check
    config_add <<-'EOF'
export [[ $PATH =~ $HOME/.jenv/bin ]] || export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
EOF
fi
source_profile
