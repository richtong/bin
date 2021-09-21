#!/usr/bin/env bash
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

ORG_NAME="${ORG_NAME:-tongfamily}"
ORG_DOMAIN="${ORG_NAME:-$ORG_NAME.com}"
export DOCKER_USER=${DOCKER_USER:-"$ORG_NAME$USER"}
export MAIN_EMAIL=${MAIN_EMAIL:-"$USER@ORG_DOMAIN"}
export GIT_USER=${GIT_USER:-"$ORG_NAME-$USER"}
export GIT_EMAIL=${GIT_EMAIL:-"$USER@$ORG_DOMAIN"}
SSH_KEY="${SSH_KEY:-"$MAIN_EMAIL-github.com.id_ed25519"}"
SECRET_FILE="${SECRET_FILE:-"$USER.vc"}"
SECRET_DRIVE="${SECRET_DRIVE:-"Google Drive"}"
SECRET_MOUNTPOINT="${SECRET_MOUNTPOINT:-"/Volume/$SECRET_FILE"}"
SSH_DIR="${SSH_DIR:-"$HOME/.ssh"}"
OPTIND=1
while getopts "hdvu:e:r:m:w:s:" opt; do
	case "$opt" in
	h)
		cat <<EOF
$SCRIPTNAME: Prebuild before install.sh can run
flags: -d debug, -h help
       -r dockeR user name (default: $DOCKER_USER)"
       -m mail for local or docker use (default: $MAIN_EMAIL)"
       -u username for git (default: $GIT_USER)"
       -e email for git (default: $GIT_EMAIL)"
       -w workspace directory"
       -s ssh key for github (default: $SSH_KEY)
EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	u)
		GIT_USER="$OPTARG"
		;;
	e)
		GIT_EMAIL="$OPTARG"
		;;
	r)
		DOCKER_USER="$OPTARG"
		;;
	m)
		MAIN_EMAIL="$OPTARG"
		;;
	w)
		export WS_DIR="$OPTARG"
		;;
	s)
		SSH_KEY="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# no include.sh run standalone
# shellcheck source=./include.sh
# if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
# source_lib lib-git.sh

set -u

echo "install homebrew and bash" >&2
if [[ $(uname) =~ Linux ]]; then
	sudo apt install -y -qq curl git
fi
if ! command -v brew >/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if [[ $(uname) =~ Linux ]] && ! command -v brew; then
	# shellcheck disable=SC2016
	if ! grep "$HOME/.profile" /home/linuxbrew; then
		echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>"$HOME/.profile"
	fi
	eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

brew update
brew install bash
brew install --cask google-drive 1password

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
		open -a "Backup and Sync"
		read -rp "Connect to $SECRET_DRIVE where your $SECRET_FILE is stored press enter to continue"
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

	brew install veracrypt
	# finds the first match for of secret file on any matching $SECRET_DRIVE
	veracrypt_secret=$(find "$HOME" -maxdepth 3 -name "$SECRET_FILE" | grep -m1 "$SECRET_DRIVE")
	if ! veracrypt -t -l "$veracrypt_secret" >/dev/null 2>&1; then
		# need to mount as block device with filesystem=none
		echo enter the password for the hidden volume this will take at least a minute
		veracrypt -t --pim=0 -k "" --protect-hidden=no --filesystem=none "$veracrypt_disk"
	fi
	# https://serverfault.com/questions/81746/bypass-ssh-key-file-permission-check/82282#82282
	# for parameters needed for msdos fat partitions
	# Need to look the second to last field because if the volume has a space cut will not work
	veracrypt_disk="$(veracrypt -t -l "$veracrypt_secret" | awk '{print $(NF-1)}')"
	if ! mount | grep -q "$veracrypt_disk"; then
		echo Enter your macOS password
		sudo mkdir -p "$SECRET_MOUNTPOINT"
		# mode must be 700 need 700 for directory access and no one else can see it
		sudo mount -t msdos -o -u="$(id -u)",-m=700 "$veracrypt_disk" "$SECRET_MOUNTPOINT"
	fi

	echo "link the keys in $SECRET_MOUNTPOINT to $SSH_DIR"

	echo "base ssh config install into .ssh"
	mkdir -p "$SSH_DIR"

	file=("$SECRET_KEY" "config")
	for f in "${file[@]}"; do
		if [[ -e SECRET_MOUNTPOINT/$f ]]; then
			ln -s "$SECRET_MOUNTPOINT/$f" "$SSH_DIR"
			chmod 600 "$SSH_DIR/$f"
		fi
	done
	chmod 700 "$SSH_DIR"

	echo "Enter passwords into keychain"
	shopt -s nullglob
	for key in "$SSH_DIR"/*; do
		ssh-add -K "$key"
	done

fi

# https://docs.github.com/en/github/authenticating-to-github/testing-your-ssh-connection
if ! ssh -T git@github.com; then
	echo "Cannot access github, check $SSH_KEY or ssh -A in VMware guest" >&2
	exit 1
fi

if ! mkdir -p "$WS_DIR/git"; then
	echo "Cannot create $WS_DIR/git" . &
	2
	exit 2
fi

git clone --recurse-submodules "https://github.com/$ORG_DOMAIN/src"

if [[ ! $OSTYPE =~ darwin ]] && ! command -v git; then
	apt-get install -y git
fi

"$SOURCE_DIR/bin/install.sh" -u "$GIT_USER" -e "GIT_EMAIL" -r "$DOCKER_USER" -m "$MAIN_EMAIL"
