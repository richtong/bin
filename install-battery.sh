#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install battery related utilities
## @author Rich Tong
## @returns 0 on success
#
# https://news.ycombinator.com/item?id=9091691 for linux gui
# https://news.ycombinator.com/item?id=8441388 for cli
# https://www.npmjs.com/package/onepass-cli for npm package
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
			Installs Battery related utilities
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
source_lib lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac; then
	exit
fi

# coconutbattery - battery life
# aldente - battery limiter to improve battery life
CASK+=(

	aldente
	coconutbattery

)

log_verbose "installng homebrew forcing to casks ${CASK[*]}"
# shellcheck disable=SC2068
if ! cask_install --force ${CASK[@]}; then
	log_warning "$? homebrew casks did not install correctly"
fi

# nosleep does not work on mac m1
# with the new do not sleep when screen closed on battery this is no longer
# needed use Amphetamine instead
#if ! mac_is_arm; then
#    "$BIN_DIR/install-nosleep.sh"
#fi

# Amphetamine - to prevent sleep instead of nosleep
MAS+=(937984704)
if ! mas_install "${MAS[@]}"; then
	log_warning "mas return $?"
fi
