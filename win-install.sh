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

if ! in_wsl; then
	log_exit "Windows only"
fi

if ! command -v scoop >/dev/null; then
	"$SCRIPT_DIR/install-scoop.ps1"
fi
if ! command -v choco.exe >/dev/null; then
	"$SCRIPT_DIR/install-choco.ps1"
fi

# https://github.com/lukesampson/psutils
# psutils adds ln, sudo and touch to Windows
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
		psutils
	)
fi

log_verbose "install ${SCOOP[*]}"
scoop install "${SCOOP[@]}"

if [[ ! -v CHOCO ]]; then
	CHOCO=(
		divvy
		epicgameslauncher
		kodi
		nordvpn
		docker-desktop
	)
fi

log_verbose "choco installation of packagers not in scoop ${CHOCO[*]}"
log_verbose "you must run in administrative mode"
runas.exe /savecred /user:administrator choco.exe install "${CHOCO[@]}"

# https://365adviser.com/powershell/install-use-openssh-windows-powershell-core-remoting-via-ssh/#:~:text=Installing%20the%20OpenSSH%20package%20Option%203%29%20using%20Chocolatey,command%3A%20choco%20install%20openssh%20-params%20%E2%80%98%E2%80%9D%2FSSHServerFeature%20%2FKeyBasedAuthenticationFeature%E2%80%9D%E2%80%98%20%E2%80%93y
log_verbose "openssh v8 is needed for git-lfs needs special installation"
runas.exe /savecredd /user:administrator choco install openssh -params ""/SSHServerFeature /KeyBasedAuthenticationFeature"" -y

"$SCRIPT_DIR/insstall-ssh.ps1"
