#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install Tailscale and set MagicDNS
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
			Installs Tailscale and Magic DNS for current network
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

	log_verbose "brew --cask install tailscale to get UI"
	package_install tailscale

	log_verbose "Determine current"
	ACTIVE="${ACTIVE:-"$(ifconfig -lu | xargs -n1 -d {} | ifconfig {} | grep active)"}"
	log_verbose "Enable 100.100.100.100 for Magic DNS on current ethernet connection"
	networksetup -setdns "$ACTIVE" 100.100.100.100

elif

	in_os linux
then

	# https://tailscale.com/kb/1031/install-linux/
	log_verbose "Install on linux just the command line"
	curl -fsSL https://tailscale.com/install.sh | sh
	if ! command -v tailscale; then
		log_error 1 "Could not install tailscale"
	fi
	log_verbose "Start tail scale and you logon with the URL supplied"
	sudo tailscale up

fi
