#!/usr/bin/env bash
##
## install Gazebo, Open Drone Map and other drone software
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
VERSION="${VERSION:-11}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Gazebo and OpenDroneMap
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help"
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
			                   -r version number (default: $VERSION)
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

tap_install dartsim/dart
brew_install dartsim
tap_install osrf/simulation
brew_install --build-from-source "gazebo$VERSION"
brew link "gazebo$VERSION"
# http://gazebosim.org/tutorials?tut=quick_start&cat=get_started
log_verbose "available worlds"
if $VERBOSE; then
	if pushd "/usr/local/share/gazebo-$VERSION/worlds" >/dev/null; then
		ls
		popd || true
	fi
fi
log_verbose "start gazebo loading worlds"
gazebo worlds/pioneers2dx.world

if ! sysctl kern.hv_support | grep "1$"; then
	log_error 1 "Cannot install open drone map need hardware virtualization"
fi
