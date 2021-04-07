#!/usr/bin/env bash
##
## Windows specific installation to make it as Unix-like as possible
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
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r version number (default: $VERSION)
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
	r)
		VERSION="$OPTARG"
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

log_verbose "In $SCRIPT_DIR"

if ! in_os windows; then
	log_exit "Windows only"
fi

if ! command -v scoop > /dev/null; then
	"$SCRIPT_DIR/install-scoop.ps1"
fi
if ! command -v choco > /dev/null; then
	"$SCRIPT_DIR/install-choco.ps1"
fi

if [[ ! -v SCOOP ]]; then
	SCOOP=(
		1password-cli
		7zip
		authy
		dark
		firefox
		gcloud
		git
		googlechrome
		jq
		lessmsi
		make
		msys2
		openssh
		potplayer
		python
		sharpkeys
		signal
		slack
		transmission
		vim
		vlc
		vscode
		windows-terminal
		zoom
	)
fi

log_verbose "install ${SCOOP[*]}"
package_install "${SCOOP[@]}"


if [[ ! -v CHOCO ]]; then
	CHOCO=(
		divvy
		epicgameslauncher
		kodi
		nordvpn
		openssh
		)
fi

log_verbose "choco installation of packagers not in scoop ${CHOCO[*]}"
choco install "${CHOCO[@]}"
