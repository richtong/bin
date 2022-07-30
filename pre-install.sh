#!/usr/bin/env bash
# vim: sw=4 ts=4:
## The above gets the latest bash on Mac or Ubuntu
##
## bootstrap to install.sh copy this down and you will have enough to get the
## src repo
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
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
	sudo apt install -y -qq curl git git-lfs
fi
if ! command -v brew >/dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

for file in .profile .bash_profile .bashrc; do
	echo "$SCRIPTNAME: no $file create a shebang" >&2
	if [[ ! -e $HOME/$file ]]; then
		echo "#!/usr/bin/env bash" >"$HOME/$file"
	fi
done

# no lib-config.sh so assume you are only doing path addition which go
# into .profile
PROFILE="${PROFILE:-"$HOME/.profile"}"
echo "$SCRIPTNAME: Set brew environment variables $PROFILE" >&2
if ! grep -q "^# Added by $SCRIPTNAME" "$PROFILE"; then
	cat >>"$PROFILE" <<-EOF
		# Added by $SCRIPTNAME on $(date)"
		if ! command -v brew >/dev/null && ! echo \$PATH | grep "\$HOMEBREW_PREFIX"; then
		            HOMEBREW_PREFIX="/opt/homebrew"
		            if  uname | grep -q Linux; then
		                HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
		            elif uname | grep -q Darwin && uname -m | grep -q x86_64; then
		                HOMEBREW_PREFIX="/usr/local"
		            fi
		            eval "\$(\$HOMEBREW_PREFIX/bin/brew shellenv)"
		        fi
	EOF
fi

echo "$SCRIPTNAME: make brew available in this script source $PROFILE" >&2
# need to turn off set -u as undefined variables is a common idium
set +u
# shellcheck disable=SC1091,SC1090
source "$PROFILE"
set -u
if ! command -v brew >/dev/null; then
	echo "$SCRIPTNAME: Brew installation failed" >&2
	exit 1
fi

brew update
# coreutils gets us readlink
for package in bash coreutils git gh; do
	if ! brew list "$package" &>/dev/null; then
		brew install "$package"
	fi
done

if [[ ! $(command -v bash) =~ $HOMEBREW_PREFIX ]]; then
	echo "$SCRIPTNAME: Brew installation of bash failed" >&2
	exit 2
fi

# https://github.com/thoughtbot/laptop/issues/447
echo "$SCRIPTNAME: change login shell to homebrew bash" >&2
if ! grep "$HOMEBREW_PREFIX/bin/bash" /etc/shells; then
	sudo tee -a /etc/shells >/dev/null <<<"$HOMEBREW_PREFIX/bin/bash"
fi
chsh -s "$HOMEBREW_PREFIX/bin/bash"

echo "$SCRIPTNAME: make sure we can see brew and coreutils on reboot"

# fail the next command if no 1Password.app
if [[ $OSTYPE =~ darwin ]]; then
	# using google drive now for rich.vc
	for package in 1password google-drive veracrypt; do
		if ! brew list "$package" &>/dev/null; then
			brew install "$package"
		fi
	done
	read -rp "$SCRIPTNAME: Login with Google Drive with Veracrypt vault, press enter when done"
	open -a "Google Drive"
elif [[ $OSTYPE =~ linux ]] && lspci | grep -q VMware; then
	echo "In VMWare assume we use 1Password and SS keys from the host"
else
	echo "In native operating system install 1Password, Google Drive and Veracrypt"
	if ! command -v 1password >/dev/null && ! command -v snap >/dev/null && ! snap install 1password >&/dev/null; then
		echo "snap install 1password failed do manually"
		# https://support.1password.com/install-linux/
		KEYRING="/usr/share/keyrings/1password-archive-keyring.gpg"
		if [[ ! -e $KEYRING ]]; then
			curl -sS https://downloads.1password.com/linux/keys/1password.asc |
				sudo gpg --dearmor --output "$KEYRING"
		fi
		REPO="https://downloads.1password.com/linux/debian/amd64"
		if ! grep -q "$REPO" /etc/apt/sources.list.d/1password.list; then
			echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] $REPO stable main" |
				sudo tee /etc/apt/sources.list.d/1password.list
		fi
		DEBSIG="/etc/debsig/policies/AC2D62742012EA22/"
		sudo mkdir -p "$DEBSIG"
		if [[ ! -e $DEBSIG/1password.pol ]]; then
			curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol |
				sudo tee "$DEBSIG/1password.pol"
		fi
		KEYRING_DIR="/usr/share/debsig/keyrings/AC2D62742012EA22"
		sudo mkdir -p "$KEYRING_DIR"
		if [[ ! -e $KEYRING_DIR/debsig.gpg ]]; then
			curl -sS https://downloads.1password.com/linux/keys/1password.asc |
				sudo gpg --dearmor --output "$KEYRING_DIR/debsig.gpg"
		fi
		sudo apt-get update -y && sudo apt-get install -y 1password
	fi

	echo "$SCRIPTNAME: install veracrypt"
	if ! command -v veracrypt >/dev/null && ! command -v snap >/dev/null && ! snap install veracrypt &>/dev/null; then
		# https://linuxhint.com/install-use-veracrypt-ubuntu-22-04/
		sudo add-apt-repository -y ppa:unit193/encryption
		sudo apt-get update -y && sudo apt-get install -y veracrypt
	fi

	# https://linuxhint.com/google_drive_installation_ubuntu/
	echo "On Ubuntu go to Settings > Online Accounts > Google and sign on"
fi

if ! mkdir -p "$WS_DIR/git"; then
	echo "SCRIPT_NAME: Cannot create $WS_DIR/git"
	exit 2
fi

if [[ ! -e "$WS_DIR/git/src" ]]; then
	gh auth login
	git clone --recurse-submodules "https://github.com/$ORG_DOMAIN/src" "$WS_DIR/git"
fi
echo "Restart the terminal to get new bash and profile"
