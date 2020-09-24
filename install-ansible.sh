#!/usr/bin/env bash
##
## install Ansible
## http://docs.ansible.com/ansible/latest/intro_installation.html
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo Install Ansible to control other machines natively and in docker
            echo usage: $SCRIPTNAME [ flags ]
            echo
            echo "flags: -d debug, -v verbose, -h help"
            echo
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
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

shift $((OPTIND-1))

if command -v ansible >/dev/null
then
    log_exit Already installed
fi

docker pull williamyeh/ansible:ubuntu16.04

if in_os mac
then
    log_verbose mac install
    package_install ansible
    if ! command -v ansible > /dev/null
    then
        log_verbose brew install failed trying pip
        pip_install --upgrade --user ansible
    fi
    log_verbose checking maxfiles limit
    if ! launchctl limit maxfiles | awk '{print $3}' | grep -q unlimited
    then
        log_verbose set maxfiles to unlimited
        sudo launchctl limit maxfiles unlimited
    fi
    exit
fi

log_verbose install ubuntu
case $(linux_distribution) in
    ubuntu)
        repository_install ppa:ansible/ansible
        ;;
    debian)
        repository_install "deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main"
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
        ;;
esac
package_install ansible

log_assert "ansible" "Ansible installed"
