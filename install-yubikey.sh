#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install Yubico Yubikey security hardware key
## @author Rich Tong
## @returns 0 on success
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
			Installs Yubico Yubikey security hardware key
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
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

source_lib lib-install.sh lib-util.sh

log_verbose "Install the Manager to set PINs and Authenticator to use for websites"

log_warning "You should have at least two Yubikeys with one locked securely to prevent lockout"

if in_os linux; then
	# https://support.yubico.com/hc/en-us/articles/360016649039-Installing-Yubico-Software-on-Linux

	log_verbose "Install Yubico Authenticator"
	snap_install yubioath-desktop
	log_verbose "Install Yubikey Manager of Keys"
	appimage_install "https://developers.yubico.com/yubikey-manager-qt/Releases/yubikey-manager-qt-latest-linux.AppImage"

	log_verbose "Check that pcscd is running"
	if ! systemctl status pcscd || ! systemctl is-enabled pcscd; then
		sudo systemctl enable --now pcscd
	fi

	# https://support.yubico.com/hc/en-us/articles/360016649099-Ubuntu-Linux-Login-Guide-U2F
	package_install libpam-u2f
	mkdir -p "$HOME/.config/Yubico"
	log_wait "Enable login by Yubikeys via U2F and press enter"
	pamu2fcfg >"$HOME/.config/Yubico/u2f_keys"
	log_wait "Insert your backup Yubico Key and press enter"
	pamu2fcfg -n >>"$HOME/.config/Yubico/u2f_keys"

	log_warning "If you encrypt your home directory this will lockout your system move to /etc for more security"

elif
	in_os mac
then
	# https://support.yubico.com/hc/en-us/articles/360016649059-Using-Your-YubiKey-as-a-Smart-Card-in-macOS
	log_verbose "install on mac"

	cask_install yubico-yubikey-manager yubico-yubikey-authenticator

	sc_auth pairing_ui -s enable
	if [[ $(sc_auth pairing_ui -s status) =~ disabled ]]; then
		sc_auth pairing_ui -s enable
	fi

fi
