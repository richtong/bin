#!/usr/bin/env bash
##
## Install private internet access vpn for ubuntu only
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME="$(basename "$0")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
DOWNLOAD_UBUNTU_URL=${DOWNLOAD_UBUNTU_URL:-"https://www.privateinternetaccess.com/installer/install_ubuntu.sh"}
# no script for non-ubuntu so need to hard code the version number
# It does automaticalliy update however
DEBIAN_VERSION="${DEBIAN_VERSION:-7.1}"
DEBIAN_SHA256="${DEBIAN_SHA256:-"3dcae01b33366832f465488122096dc1645a2632298c823188c3675750cc3233"}"
# note we need to remove the decimals when going to the url
# https://unix.stackexchange.com/questions/104881/remove-particular-characters-from-a-variable-using-bash
DOWNLOAD_DEBIAN_URL=${DOWNLOAD_DEBIAN_URL:-"https://installers.privateinternetaccess.com/download/pia-v${DEBIAN_VERSION//./}-installer-linux.tar.gz"}
while getopts "hdvw:x:u:n:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: flags: -d debug, -h help"
		echo "    -w ws directory"
		echo "    -x extract into download directory (default: $DOWNLOAD_DIR)"
		echo "    -u url for the download for ubuntu (default: $DOWNLOAD_UBUNTU_URL)"
		echo "    -n version for the debian download (default: $DEBIAN_VERSION)"
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
	x)
		DOWNLOAD_DIR="$OPTARG"
		;;
	u)
		DOWNLOAD_UBUNTU_URL="$OPTARG"
		;;
	n)
		DEBIAN_VERSION="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh
# need this line below because WS_DIR defined by include.sh
DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$WS_DIR/cache"}

if in_os mac; then
	package_install private-internet-access
	if [[ ! -e "/Applications/Private Internet Access.app" ]]; then
		log_verbose no Private Internet Access application found
		if [[ ! -e "/Volumes/Private Internet Access" ]]; then
			log_verbose no PIA installer volume found
			DMG=$(find "$HOME" -name "Downloads/pia-v*-installer-mac.dmg" | head -1)
			if [[ -z $DMG ]]; then
				log_verbose no PIA DMG found so download it wait 30 seconds for
				open "https://www.privateinternetaccess.com/installer/download_installer_osx"
				sleep 30
			fi
			log_verbose got the DMG now mount it
			hdiutil mount "$DMG"
		fi
		log_verbose find the installer in the volume note this installer detaches
		open "$(find_in_volume "Private Internet Access Installer.app" "Private Internet Access")"
	fi
	exit
fi

log_verbose installing linux variants
mkdir -p "$DOWNLOAD_DIR"
pushd "$DOWNLOAD_DIR" >/dev/null

if in_linux ubuntu; then
	log_verbose ubuntu installation
	if dpkg -s network-manager-openvpn | grep -q "ok installed"; then
		exit 0
	fi
	file="$(basename "$DOWNLOAD_UBUNTU_URL")"
	download_url "$DOWNLOAD_UBUNTU_URL" "$file" "$DOWNLOAD_DIR"
	sudo sh "$file"
	log_verbose "We need to wait a little because on linux, the network goes down and then"
	log_verbose up after the install
	sleep 20

else
	log_verbose generic Linux installation
	download_url "$DOWNLOAD_DEBIAN_URL" "$file" "$DOWNLOAD_DIR" "0" "$DEBIAN_SHA256"
	# in case there are more than one just run the first file found
	file="$(extract_tar "$(basename "$DOWNLOAD_DEBIAN_URL")" | head -1)"
	log_verbose "running $file"
	sh "./$file"
fi

popd >/dev/null
