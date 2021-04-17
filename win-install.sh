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
ADMIN="${ADMIN:-service-account}"
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
source_lib lib-install.sh lib-util.sh lib-win.sh

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
		visualstudio2019community
	)
fi

log_verbose "choco installation of packagers not in scoop ${CHOCO[*]}"
# https://superuser.com/questions/108207/how-to-run-a-powershell-script-as-administrator
# runas does not work
#runas.exe /savecred /user:"$ADMIN" "choco.exe install ${CHOCO[*]}"
win_sudo "choco install ${CHOCO[*]}"

# https://365adviser.com/powershell/install-use-openssh-windows-powershell-core-remoting-via-ssh/
log_verbose "openssh v8 is needed for git-lfs needs special installation"
# do not add SCRIPT_DIR we use cwd as Linux paths are not windows paths
log_verbose "install-ssh.ps1 Powershell script not correctly called quote issue"
#win_sudo '-f install-ssh.ps1'
# note you need a path here not just a file name and the path needs to be a
# windows one not a WSL2 one, but ./ for current directory works
win_sudo ./install-ssh.ps1
log_warning "sshd starting requires reboot"

# https://www.partitionwizard.com/partitionmagic/enable-remote-desktop-windows-10.html
log_verbose "Now enable Remote Desktop Server with cmd.exe"
# firewall is already set properly and these are not correct anyway
#cmd.exe reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" \
	#/v fDenyTSConnectionsd /t REG_DWORD /d 0 /f
# win_sudo 'Enable-NetFirewallRule -DisplayGroup "Remote Desktop"'
#cmd.exe netsh advfirewall firewall set rul group="remote desktop" new enable=yes

log_warning "Enable Remote Desktop with powershell does not work use Settings > System > Remote Desktop"
log_warning "Will not work in Windows Home"
win_sudo Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnection" -Value 0
