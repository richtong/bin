#!/usr/bin/env bash
##
## Install Open Broadcast Studio
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

NDI_VERSION="${NDI_VERSION:-4.5.1}"
REMOVAL_VERSION="${REMOVAL_VERSION:-v0.4.0}"
OBS_CONTENT="${OBS_CONTENT:-/Applications/OBS.app/Contents}"

FORCE="${FORCE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvfn:r:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Open Broadcast Studio, NDI and Background Removal
			    usage: $SCRIPTNAME [ flags ]
				flags: -h help"
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
			                   -f $($FORCE && echo "no")force Homebrew install
			                   -n NDI Version number (default: $NDI_VERSION)
			                   -r OBS Background Removal (default: $REMOVAL_VERSION)
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
		export VERBOSE=true
		;;
	n)
		NDI_VERSION="$OPTARG"
		;;
	r)
		REMOVAL_VERSION="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if $FORCE; then
	FLAG=(--force)
fi

if in_os mac; then

	# shellcheck disable=SC2068
	package_install ${FLAG[@]} obs obs-ndi

	NDI="${NDI:-"https://downloads.ndi.tv/Tools/NDIToolsInstaller.pkg"}"
	log_verbose "open $NDI"
	download_url_open "$NDI"
	log_warning "Restart is required to get NDI and you should see a menu bar item"
	log_verbose "Install NDI Virtual Input as a login item"
	mac_login_item_add "/Applications/NDI Virtual Input.app"

	log_verbose "Install plugins"
	URL+=(

		"https://github.com/royshil/obs-backgroundremoval/releases/download/$REMOVAL_VERSION/obs-backgroundremoval-macosx.zip"

	)

	for url in "${URL[@]}"; do
		log_verbose download_url_open "$url" "${url##*/}" "$WS_DIR/cache" "$OBS_CONTENT"
		download_url_open "$url" "${url##*/}" "$WS_DIR/cache" "$OBS_CONTENT"
	done

elif in_os linux; then

	# >https://obsproject.com/wiki/install-instructions#supported-builds

	apt_repository_install "ppa:obsproject/obs-studio"
	apt_install "obs-studio"

fi
