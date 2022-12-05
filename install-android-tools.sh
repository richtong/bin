#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install 1Password
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
VERBOSE="${VERBOSE:-false}"
DEBUGGING="${DEBUGGING:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Android Tools
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

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if in_os mac; then
	# https://medium.com/macoclock/launch-adb-installed-by-homebrew-on-macos-59d87f4336c8
	cask_install android-studio android-platform-tools
	log_warning "To complete installation, start Android Studio and download the SDK"
elif in_os linux; then
	package_install adb android-sdk-platform-tools-common
	# https://askubuntu.com/questions/634082/how-to-install-android-studio-on-ubuntu
	snap_install --classic android-studio
fi

package_install scrcpy
