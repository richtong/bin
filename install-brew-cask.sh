#!/usr/bin/env bash
##
## Install a brew cask with retries
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

CASK=${CASK:-"bash-completion"}
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install a brew cask
            echo "flags: -d debug, -v verbose, -h help"
            echo "positional: cask... (default: $CASK)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
set -u
shift $((OPTIND-1))
source_lib lib-util.sh

log_verbose all positionals fed to brew
if (( $# >= 1 ))
then
    CASK="$@"
    shift
fi

if ! in_os mac
then
    log_verbose Mac only
    exit
fi

log_verbose attempt update install
if ! brew install $CASK
then
    log_verbose update in place failed, try to unlink first
    brew unlink $CASK
    brew install $CASK
fi


# https://www.safaribooksonline.com/blog/2014/03/18/keeping-homebrew-date/
log_verbose update brew
brew update
brew upgrade
