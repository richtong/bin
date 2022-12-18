#!/usr/bin/env bash
##
## Deprecated now that Travis supports 14.04

## Installation npm suitable for m2 on Ubuntu earlier than 14.04
## which we can use to install locally something that looks like the
## travis-ci.com build environment which is good for DEBUGGING
##
##
## These are the minimums to run m2 build
## In this case we need node > 0.10 which gives us a good npm
## Also need git of at least 1.8
##
## @author Rich Tong
## @returns 0 on success
#
# we don't have ws-env.sh available to us at bootstrap time
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME flags: -d debug, -h help"
		exit 0
		;;
	d)
		# -x is x-ray or detailed trace, -v is verbose, trap DEBUG single steps
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-version-compare.sh

log_exit "this is deprecated use add dist: trusty to .travis.yml"

##install
##@param $1 package name
##@param $2 ppa repository
function install() {
	$DEBUGGING && echo "$SCRIPTNAME: installing $1 from $2"
	sudo apt-get install -y python-software-properties
	sudo add-apt-repository -r -y "$2"
	sudo add-apt-repository -y "$2"
	sudo apt-get update
	sudo apt-get install -y "$1"
}

log_verbose "testing nodejs -v"
# node sticks a 'v' in front so add a v to version 0.10
if ! command -v nodejs || verlt "$(nodejs -v)" v0.10; then
	install "nodejs" "ppa:chris-lea/node.js"
fi

if ! command -v git || verlt "$(git version | cut -f3 -d' ')" 1.9; then
	install "git" "ppa:git-core/ppa"
fi
