#!/usr/bin/env bash
##
## install docker toolbox for mac
## This is deprecated for the new docker for mac as of July 2016
## but some older mac's will need it as it requires hardware support
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DOCKER_VERSION=${DOCKER_VERSION:-1.12.0}
DOCKER_TOOLBOX_URL=${DOCKER_TOOLBOX_URL:-"https://github.com/docker/toolbox/releases/download/v$DOCKER_VERSION/DockerToolbox-$DOCKER_VERSION.pkg"}
OPTIND=1
while getopts "hdvr:u:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install docker toolbox"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -r docker version (default: $DOCKER_VERSION)"
		echo "       -u docker download url (default: $DOCKER_TOOLBOX_URL)"
		exit 0
		;;
	d)
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
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-version-compare.sh lib-install.sh lib-util.sh

set -u
shift $((OPTIND - 1))

# pulls things assuming your git directory is $WS_DIR/git a la Sam's convention
# There is an optional 2nd parameter for the repo defaults to organization repo

# http://blog.docker.com/2015/07/new-apt-and-yum-repos/#more-6860
if ! in_os mac; then
	log_verbose only for Mac
	exit 0
fi

# we do not install from packages because docker toolbox gives us
# virtualization and sets up the default vm
#log_verbose Darwin packages are up to date from mac ports, so just install
#package_install docker docker-machine curl
log_warning this installs docker toolbox for most macs you want docker for mac

if command -v docker && vergte "$(docker -v | cut -d ' ' -f3)" "$DOCKER_VERSION"; then
	log_verbose at the latest version
	exit
fi

log_verbose uninstall MacPorts versions if they are present
package_uninstall docker-machine docker-compose docker

log_verbose install docker toolbox for Mac
download_url_open "$DOCKER_TOOLBOX_URL"

# http://stackoverflow.com/questions/28315383/how-to-silently-install-a-pkg-file-in-mac-os-x
# sudo installer -store -pkg "$PKG" -target /
# Note the installer does not handle upgrades properly so use the gui
# instead
# sudo installer -pkg "$PKG" -target /
