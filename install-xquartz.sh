#!/usr/bin/env bash
##
## install xQuartz
## See https://www.xquartz.org
## note that the mac ports version is 1.8 and will not run on El Capitan
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

VERSION=${VERSION:-2.7.9}
CONFIG="${CONFIG:-/etc/ssh/sshd_config}"
DOWNLOAD_URL="${DOWNLOAD_URL:-"https://dl.bintray.com/xquartz/downloads/XQuartz-$VERSION.dmg"}"
OPTIND=1
while getopts "hdvr:c:" opt; do
	case "$opt" in
	h)
		cat <<EOF
Install XQuartz
usage: $SCRIPTNAME [ flags ]
flags: -d debug, -v verbose, -h help
       -r release to download (default: $VERSION)
       -c location of sshd_config and ssh_config (default: $CONFIG)
EOF
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
	c)
		CONFIG="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-config.sh lib-util.sh
shift $((OPTIND - 1))

if ! in_os mac; then
	log_exit Only for Mac
fi

log_verbose "install using brew"
# https://apple.stackexchange.com/questions/224373/install-xquartz-using-homebrew-on-mac-os-x-el-capitan
if ! command -v brew >/dev/null; then
	"$SCRIPT_DIR/install-brew.sh"
fi

cask_install xquartz
if [[ ! -e /Applications/Utilities/XQuartz.app ]]; then
	log_verbose falling back to dmg installation
	download_url_open "$DOWNLOAD_URL"
	# look for XQuartz in a volume prefixed by the name XQuartz
	find_in_volume_open_then_detach XQuartz.pkg XQuartz
fi

log_assert "[[ -e /Applications/Utilities/XQuartz.app ]]" "XQuartz installed"

log_verbose "making sure the $CONFIG allows X11 forwarding which can be reset on MacOS upgrades"

# https://stackoverflow.com/questions/39622173/cant-run-ssh-x-on-macos-sierra
# note that when you are passing this, you need to make sure not to quote the
# entire line  don't quote it
config_add_once "$CONFIG" X11Forwarding yes
config_add_once "$CONFIG" X11DisplayOffset 10
# This location changed with Sierra apparently
config_add_once "$CONFIG" XAuthLocation /opt/X11/bin/xauth

log_verbose make sure the client allows X11 forwarding
config_add_once "$HOME/.ssh/config" "XAuthLocation /opt/X11/bin/xauth"
config_add_once "$HOME/.ssh/config" "ForwardX11Timeout 596h"

# make sure we have all the bash settings not needed rn but for safety
source_profile

# Enable OpenGL in XQuartz
# https://services.dartmouth.edu/TDClient/1806/Portal/KB/ArticleDet?ID=89669
log_verbose "Enableing iglx for OpenGL support"
defaults write org.xquartz.X11 enable_iglx -bool true

# https://stackoverflow.com/questions/28392949/running-chromium-inside-docker-gtk-cannot-open-display-0/34586732#comment63471630_28395350
log_warning "Start XQuartz and in Preference > Network > Security > Allow"
log_warning "connections from network client"
log_warning "use xhost to connect to allow local docker access"
# shellcheck disable=SC2016
log_warning 'Enable it with host "+$HOSTNAME" +localhost'

if $VERBOSE; then
	log_verbose "Starting XQuartz"
	open -a XQuartz
	log_verbose "adding host names"
	xhost +localhost "+$HOSTNAME"

	# https://unix.stackexchange.com/questions/118811/why-cant-i-run-gui-apps-from-root-no-protocol-specified
	log_verbose "checking X authentication active and allowed network addresses"
	xauth info
	xauth list
	log_verbose "Query if glxinfo works"
	# https://dri.freedesktop.org/wiki/glxinfo/
	glxinfo | grep render
	log_verbose "Should say direct rendering: Yes and OpenGL Renderer string points to hardware"
	for test in xeyes glxgears; do
		log_verbose "run $test for 10 seconds to verify then quit"
		"$test" &
		sleep 10
		pkill "$test"
	done
	log_verbose "Test Docker access"
	open -a Docker
	sleep 10
	docker run -d --rm --name firefox -e DISPLAY=host.docker.internal:0 jess/firefox
	sleep 10
	docker stop firefox

	# https://osxdaily.com/2014/09/05/gracefully-quit-application-command-line/
	osascript -e 'quit app "XQuartz"'
fi
