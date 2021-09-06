#!/usr/bin/env bash
##
## install PX4
## https://docs.px4.io/master/en/dev_setup/dev_env_mac.html
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
VERSION="${VERSION:-7}"
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs PX4 and Simulators
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac; then
	log_exit "MacOS only"
	# obsoleted by official 1passworld cli
	# https://app-updates.agilebits.com/product_history/CLI
	## https://www.npmjs.com/package/onepass-cli for npm package
	# git_install_or_update 1pass georgebrock
fi

TAP+=(
	px4/px4
	adoptopenjdk/openjdk
)
PACKAGE+=(
	px4-dev
	xquartz
	px4-sim-gazebo
	adoptopenjdk15
	px4-sim-jmavsim
)

URL+=(
	https://s3-us-west-2.amazonaws.com/qgroundcontrol/builds/master/QGroundControl.dmg
)

log_verbose "tapping ${TAP[*]}"
tap_install "${TAP[@]}"

log_verbose "install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

for url in "${URL[@]}"
do
	log_verbose "opening ${URL[*]}"
	download_url_open "$url"
done
