#!/usr/bin/env bash
##
## install enpass passowrd maanger
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install Enpass Password Manager
				flags: -d debug, -v verbose, -h help
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt"
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
shift $((OPTIND - 1))
source_lib lib-util.sh lib-install.sh lib-mac.sh

if in_os mac; then

	if ! brew cask install enpass; then
		log_verbose Install from Enpass from Mac Apps store as that version includes iCloud Sync
		mas install 732710998
		log_exit Enpass installed from Mac Apps store
	fi
	log_exit Enpass installed with brew
fi

if in_linux ubuntu; then
	log_verbose ubuntu installation
	apt_repository_install "deb http://repo.sinew.in/ stable main"
	curl -L "https://dl.sinew.in/keys/enpass-linux.key" | sudo apt-key add -
	package_install enpass
fi

if [[ $(desktop_environment) =~ xfce ]]; then
	log_warning xfce does not support enpass standard repo install
fi
