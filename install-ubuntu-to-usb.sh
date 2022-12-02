#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## create Ubuntu USB stick
## https://ubuntu.com/tutorials/install-ubuntu-desktop#3-create-a-bootable-usb-stick
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
			Create Ubuntu USB stick
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
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
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-install.sh lib-util.sh

if ! in_os mac; then
	log_exit "Mac only"
fi

package_install balenaetcher

log_warning "For 20.04 enter https://releases.ubuntu.com/20.04/ubuntu-20.04.5-desktop-amd64.iso"
log_warning "For 22.04 enter https://www.releases.ubuntu.com/22.04/ubuntu-22.04.1-desktop-amd64.iso"
log_warning "You will need a 16GB USB drive and run Balena Etcher"
