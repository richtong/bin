#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install git lfs from package cloud
## Note we are trusting them as we are doing a sudo bash!
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
VERSION=${VERSION:-"1.2.0"}
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install git lfs"
		echo "flags: -d debug, -h help"
		echo "       -r git lfs version (default $VERSION)"
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
DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$HOME/Downloads/git-lfs-$VERSION"}
DOWNLOAD_URL=${DOWNLOAD_URL:-"https://github.com/github/git-lfs/releases/download/v$VERSION/git-lfs-darwin-amd64-$VERSION.tar.gz"}
source_lib lib-install.sh lib-mac.sh lib-util.sh

if command -v git-lfs; then
	exit 0
fi

if in_os mac; then
	package_install git-lfs
	if ! command -v git-lfs; then
		if [[ ! -e "$DOWNLOAD_DIR" ]]; then
			download_url_open "$DOWNLOAD_URL"
		fi
		# Note that the git install must be run out of the working directory
		if ! cd "$DOWNLOAD_DIR"; then
			log_error 1 "no $DOWNLOAD_DIR"
		fi
		sudo "./install.sh"
		cd - || false
	fi
else
	curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
	package_install git-lfs
	git lfs install
fi
