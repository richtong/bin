#!/usr/bin/env bash
##
## install 1Password Unifi controller
## As of version 4.11.47 needs Java 8
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
VERSION="${VERSION:-8}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Unifi and the prerequisites which is Java 8
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
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-mac.sh lib-install.sh

if [[ ! $OSTYPE =~ darwin ]]; then
	log_exit "Mac only"
fi

cask_install ubiquiti-unifi-controller
log_verbose make sure we are running Java 8 which is really called version 1.8
"$SCRIPT_DIR/install-java.sh" -r "$VERSION"

if [[ ! -e /Applications/UniFi.app/Contents/Home ]]; then
	log_exit Could not find the UniFi Application and set the JDK version
fi

if ! pushd "/Applications/UniFi.app/Contents/Home" >/dev/null; then
	log_error 1 "no Unifi.app"
fi

sudo jenv local 1.8

log_verbose as of October 2019 installing the JDK does not work you need to
log_verbose manually install the JRE 1.8 from the Oracle website
