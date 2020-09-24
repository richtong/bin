#!/usr/bin/env bash
##
## Installs Node Version Manager
#
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-" -v "}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs node version manager
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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh lib-util.sh
shift $((OPTIND-1))

"$SCRIPT_DIR/install-brew.sh"

brew_install nvm
mkdir -p "$HOME/.nvm"

profile="$HOME/.bashrc"
if in_os mac
then
    profile="$HOME/.bash_profile"
fi

# http://dev.topheman.com/install-nvm-with-homebrew-to-use-multiple-versions-of-node-and-iojs-easily/
log_verbose installing nvm
if ! config_mark
then
    # note we quote "EOF" so there is no bash substitutions
    config_add <<-"EOF"
export NVM_DIR="$HOME/.nvm"
source "$(brew --prefix nvm)/nvm.sh
EOF
fi
