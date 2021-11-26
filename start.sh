#!/usr/bin/env bash
# vi: sw=4 ts=4 et :
## The above gets the latest bash on Mac or Ubuntu
##
## bootstrap to install.sh copy this down and you will have enough to get the
## src repo
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

ORG_DOMAIN="${ORG_DOMAIN:-"richtong"}"
WS_DIR="${WS_DIR:-"$HOME/ws"}"
OPTIND=1
while getopts "hdvu:e:r:m:w:s:f:c:l:o:x:" opt; do
	case "$opt" in
	h)
	cat <<EOF
$SCRIPTNAME: Prebuild before install.sh can run requires no other files
	It installs assuming Bash 3.x and add 1Password and a shared Drive
	This looks for the veracrypt volume with the the keys
	Then links to the key one and copies in a temporary ssh config

flags: -h help
       -x ssh directory (default:$SSH_DIR)
EOF

		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
# if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u

echo "install homebrew and bash" >&2
if [[ $(uname) =~ Linux ]]; then
	sudo apt install -y -qq curl git
fi
if ! command -v brew >/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# make sure on reboot we can see it
if ! grep shellenv "$HOME/.profile"; then
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.profile"
fi
# make sure we can see brew
eval "$(/opt/homebrew/bin/brew shellenv)"

if [[ $(uname) =~ Linux ]] && ! command -v brew; then
	# shellcheck disable=SC2016
	if ! grep "$HOME/.profile" /home/linuxbrew; then
		echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.profile"
	fi
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew update
brew install bash git gh
# using google drive now for rich.vc
brew install 1password google-drive 

# fail the next command if no 1Password.app
if [[ $OSTYPE =~ linux ]] && lspci | grep -q VMware; then
	echo "In VMWare assume we use 1Password and SS keys from the host"
else
	echo "In Native operating system install 1Password, Google Drive and
	Veracrypt"
	if [[ $OSTYPE =~ darwin ]]; then
		shopt -s failglob
		open -a "/Applications/1Password"*.app
		shopt -u failglob
		read -rp "Connect to 1Password and press enter to continue"
		open -a "Google Drive"
		read -rp "Connect to the user account with the Veracrypt with the ssh keys"
	else
		echo "On Ubuntu go to Settings > Online Accounts > Google and sign on"
		# https://support.1password.com/install-linux/
		curl -sS https://downloads.1password.com/linux/keys/1password.asc |
			sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
		echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' |
			sudo tee /etc/apt/sources.list.d/1password.list
		sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
		curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
			sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
		sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
		curl -sS https://downloads.1password.com/linux/keys/1password.asc |
			sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
	fi


fi

if ! mkdir -p "$WS_DIR/git"; then
	echo "Cannot create $WS_DIR/git" 
	exit 2
fi

if [[ ! -e "$WS_DIR/git/src" ]]; then
    gh auth login
	git clone --recurse-submodules "https://github.com/$ORG_DOMAIN/src" "$WS_DIR/git"
fi
echo "Restart the terminal or source .profile and .bash_profile and start a new bash"
