#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
# Install flocker docker volume manager
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvw:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: flags: -d debug, -h help"
		echo "-w change the ws dir"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt"
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

CACHE_ROOT_DIR=${CACHE_ROOT_DIR:-"$WS_DIR/cache"}

set -u

# https://docs.clusterhq.com/en/1.5.0/install/install-client.html#ubuntu-14-04
sudo apt-get -y install apt-transport-https software-properties-common
if ! grep "^deb https://clusterhq" /etc/apt/sources.list; then
	sudo add-apt-repository -y "deb https://clusterhq-archive.s3.amazonaws.com/ubuntu/$(lsb_release --release --short)/\$(ARCH) /"
	sudo apt-get update -y
fi
sudo apt-get -y --force-yes install clusterhq-flocker-cli
