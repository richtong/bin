#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install Remote Desktop (rdp)
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
			G      -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
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
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-install.sh

if in_os mac; then
	log_verbose "install Mac RDP"
	# https://apps.apple.com/us/app/microsoft-remote-desktop
	mas_install 1295203466

elif in_os linux; then

	if sudo systemctl status xrdp >/dev/null; then
		log_verbose "RDP already installed"
	fi
	# https://linuxize.com/post/how-to-install-xrdp-on-ubuntu-20-04/
	log_verbose "No RDP install xrdp"
	package_install xrdp
	log_verbose "Add xrdp to ssl-cert group"
	sudo adduser xrdp ssl-cert
	log_verbose "restart xrdp to add ssl-cert"
	log_verbose "if ufw is active enable port 3389"
	sudo systemctl restart xrdp

	# https://ubuntututorials.org/ubuntu-20-04-xrdp-black-screen/
	log_warning "You cannot be logged into to the local interface while trying to RDP in"
	# https://github.com/neutrinolabs/xorgxrdp/issues/164
	log_verbose "Ubuntu 20.04 adding Option CoreKeyboard and Option CorePointer"
	grep -q 'Option "CoreKeyboard"' /etc/X11/xrdp/xorg.conf ||
		sudo sed -i '/^[[:blank:]]*Driver "xrdpkeyb"/a\    Option "CoreKeyboard"' /etc/X11/xrdp/xorg.conf
	grep -q 'Option "CorePointer"' /etc/X11/xrdp/xorg.conf ||
		sudo sed -i '/^[[:blank:]]*Driver "xrdpmouse"/a\    Option "CorePointer"' /etc/X11/xrdp/xorg.conf
fi
