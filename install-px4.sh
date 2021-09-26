#!/usr/bin/env bash
##
## install PX4
## https://docs.px4.io/master/en/dev_setup/dev_env_mac.html
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# https://unix.stackexchange.com/questions/15998/what-does-the-e-do-in-a-bash-shebang
# https://coderwall.com/p/fkfaqq/safer-bash-scripts-with-set-euxo-pipefail
# the -e flag says exist if any part of the pipeline fails it should
set -eo pipefail
# this replace set -e by running exit on any error use for bashdb
# but as of september 2021 this causes bashdb to fail
#trap 'exit $?' ERR
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

source_lib lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

if ! in_os mac; then
	log_exit "MacOS only"
	# obsoleted by official 1passworld cli
	# https://app-updates.agilebits.com/product_history/CLI
	## https://www.npmjs.com/package/onepass-cli for npm package
	# git_install_or_update 1pass georgebrock
fi

if ! config_mark; then
	log_verbose "set file ulimit higher"
	# this no longer seems to work in Bash 5.0
	config_add <<<"ulimit -S -n 2048"
	source_profile
fi

log_verbose "Install XQuartz for simulator output"
"$SCRIPT_DIR/install-xquartz.sh"

TAP+=(
	px4/px4
	adoptopenjdk/openjdk
)
# Note as of September 2021, jdk16 is required
# parallels used for ubuntu installation on MacOS
PACKAGE+=(
	px4-dev
	px4-sim-gazebo
	adoptopenjdk16
	px4-sim-jmavsim
	qgroundcontrol
	visual-studio-code
	parallels
)

log_verbose "tapping ${TAP[*]}"
tap_install "${TAP[@]}"

log_warning "check for bash_completion conflicts between v1 and v2"
if brew_conflict bash-completion@2 bash-completion "${PACKAGE[@]}"; then
	log_verbose "conflict with bash-completion, unlinkj bash-completion@2"
	brew unlink bash-completion@2
fi

log_verbose "install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

if brew_conflict bash-completion@2 bash-completion "${PACKAGE[@]}"; then
	log_verbose "installation complete relinking bash-completion2"
	brew unlink bash-completion
	brew link bash-completion@2
fi
log_verbose "As of September 2021 use tbb@2020 as tbb@2021 is incompatible"
brew unlink tbb
brew_install tbb@2020
brew link tbb@2020

# python-json2yaml is to convert yaml into QGC .plan files
PYTHON+=(
	pyserial
	empy
	toml
	numpy
	pandas
	jinja2
	pyyaml
	pyros-genmsg
	python-json2yaml
)
log_verbose "Install PIP packages"
pip_install "${PYTHON[@]}"

# https://askubuntu.com/questions/1092742/where-should-i-put-appimages-files
APPIMAGE="${APPIMAGE:-"https://s3-us-west-2.amazonaws.com/qgroundcontrol/builds/master/QGroundControl.AppImage"}"
log_verbose "Download linux daily build from $APPIMAGE"
download_url "$APPIMAGE"

if osascript -e 'id of application "QGroundControl"' >/dev/null >&1; then
	log_warning "qgroundcontrol is already installed as homebrew stable"
fi
DMG="${DMG:-"https://s3-us-west-2.amazonaws.com/qgroundcontrol/builds/master/QGroundControl.dmg"}"
log_verbose "Download daily build from $DMG"
download_url_open "$DMG"
VOLUME="${VOLUME:-QGroundControl}"
log_verbose "Looking for the first /Volume/$VOLUME"
FOUND=$(find /Volume -name "$VOLUME*" -quit)
if [[ -n $FOUND && -e $FOUND/QGroundControl.app ]]; then
	log_verbose "Found daily build at $FOUND/QGroundControl.app moving to $HOME/Applications"
	mv "$FOUND/QGroundControl.app" "$HOME/Applications"
else
	log_warning "No daily build found"
fi

DMG="${DMG:="https://s3-us-west-2.amazonaws.com/qgroundcontrol/builds/master/QGroundControl.dmg"}"
log_verbose "Downloading $DMG for versions later than in homebrew"
download_url_open "$DMG"
