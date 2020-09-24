#!/usr/bin/env bash
##
## install vagrant for Mac using Homebrew
## http://sourabhbajaj.com/mac-setup/Vagrant/README.html
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install Vagrant
            echo "flags: -d debug, -v verbose, -h help"
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
if [[ $SCRIPT_DIR =~ /Volumes ]]
then
    source lib-git.sh lib-mac.sh
else
    source_lib lib-git.sh lib-mac.sh
fi

set -u
shift $((OPTIND-1))


TEMP=$(mktemp -d)
log_verbose tests run in $TEMP

log_verbose set clean of temp files
trap "rm -rf "$TEMP"" ERR EXIT

if [[ $OSTYPE =~ darwin ]]
then
    brew cask install virtualbox
    brew cask install vagrant
    brew cask install vagrant-manager

    log_verbose validate install
    hash -r
    if ! vagrant box list | grep -q '^precise64'
    then
        vagrant box add precise64 http://files.vagrantup.com/precise64.box
    fi
    cd "$TEMP"
    vagrant init precise64
    vagrant up
    vagrant ssh -c "uname -a"
    vagrant halt
    vagrant box remove precise64
    cd -
else
    log_verbose Only for Mac
fi
