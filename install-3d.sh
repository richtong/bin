#!/usr/bin/env bash
##
## install WebODM tools
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
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Photogrammetry tools to convert photos to 3D models
			including  WebODM, qgix, cloudcompare, meshlab, epic-games unreal, unity
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
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac; then
	log_exit "Mac Only"
fi

# epic-games - unreal deprecated for unity
if [[ ! -v TOOLS ]]; then
	TOOLS=(

		cloudcompare
		meshlab
		plastiscam
		qgis
		unity-hub
		unity

	)
fi

# https://forum.unity.com/threads/unity-hub-fails-to-find-license.835423/
log_warning "Run Unity Hub to get the Unity License File before runnning Unity"
log_warning "or Copy license into /Library/Application Support/Unity/Unity_lic.ulf before starting"
package_install "${TOOLS[@]}"

log_verbose "Install "
sudo installer -package Unity.pkg -target /

# https://github.com/alicevision/AliceVision/issues/1071
log_verbose "Installing AliceVision currently needs CUDA to run"

# https://connected-environments.org/making/photogrammetry-for-mac-users/
log_verbose "Installing Regard3D via URL"
download_url_and_open "https://sourceforge.net/projects/regard3d/files/latest/download"
log_verbose "Install Pcx into Unity to render point clouds"
