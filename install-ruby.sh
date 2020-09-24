#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Installs the latest ruby
##
## Note travis needs at least 1.9.3 for version 1.8
##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            echo "$SCRIPTNAME: install ruby"
            echo  "flags: -d debug, -h help, -r ruby version"
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            ;;
        r)
            VERSION="$OPTARG"
            ;;
        *)
            echo "no -$opt" >&2
            ;;
    esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-version-compare.sh lib-util.sh lib-config.sh

VERSION=${VERSION:-2.1}

set -u

if in_os mac
then
    brew install ruby
    if ! config_mark
    then
        # shellcheck disable=SC2016
        config_add <<<'export PATH="/usr/local/opt/ruby/bin:$PATH"'
    fi
    exit
fi

# For travis using 12.04, need different install
# http://stackoverflow.com/questions/4023830/bash-how-compare-two-strings-in-version-format
##install
##@param $1 package name
##@param $2 ppa repository
install() {
    log_verbose "installing $1 from $2"
    sudo apt-get install -y python-software-properties
    sudo add-apt-repository -r -y  "$2"
    sudo add-apt-repository -y "$2"
    sudo apt-get update
    sudo apt-get install -y "$1"
}

if ! command -v ruby || verlt "$(ruby -v | cut -d' ' -f 2)" 1.9.3
then
    install "ruby2.1" "ppa:brightbox/ruby-ng"
    sudo apt-get install -y ruby-switch "ruby$VERSION-dev"
    sudo ruby-switch --set ruby "$VERSION"
fi
