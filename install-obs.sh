#!/usr/bin/env bash
##
## Install Open Broadcast Studio
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			    usage: $SCRIPTNAME [ flags ]
				flags: -d debug (not functional use bashdb), -v verbose, -h help"
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
	log_exit "No Linux"
fi

NDI_VERSION="${NDI_VERSION:-4.5.1}"
NDI="${NDI:-"https://downloads.ndi.tv/Tools/NDIToolsInstaller.pkg"}"
log_verbose "open $NDI"
download_url_open "$NDI"
log_warning "Restart is required to get NDI and you should see a menu bar item"
log_verbose "Install NDI Virtual Input as a login item"
# https://stackoverflow.com/questions/6947925/add-app-to-osx-login-items-during-a-package-maker-installer-postflight-script/7643260#7643260
# https://stackoverflow.com/questions/9483959/osx-10-8-loginitems
defaults write "$HOME/Library/Preferences/loginwindow" \
	AutoLaunchedApplicationDictionary -array-add \
	-array-add '{ "Path" = "/Applications/NDI Virtual Input.app"; "Hide" = "0"; }'

package_install obs obs-ndi

log_verbose "Install plugins"
VERSION="${VERSION:-v0.3.0-beta}"
URL+=( "https://github.com/royshil/obs-backgroundremoval/releases/download/$VERSION/obs-backgroundremoval-macosx.zip" )
APP="${APP:-/Applications/OBS.app/Contents}"

for url in "${URL[@]}"; do
	log_verbose download_url "$url" "${url##*/}" "$WS_DIR/cache" "$APP"
	download_url_open "$url" "${url##*/}" "$WS_DIR/cache" "$APP"
done
