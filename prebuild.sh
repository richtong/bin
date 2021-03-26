#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## bootstrap to install.sh
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
SSH_KEY="${SSH_KEY:-"rich@tongfamily.com-github.com.id_ed25519"}"
PYTHON="${PYTHON:-3.9}"
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

echo "install homebrew" >&2
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update
brew install bash python@3.9

echo "base ssh config install into .ssh"
mkdir -p "$HOME/.ssh"

# https://docs.github.com/en/github/authenticating-to-github/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
SSH="$HOME/.ssh"
echo "assumed you have installed $SSHKEY into ~/.ssh" >&2
if [[ ! -e $SSH/config ]]; then
	cat > "$SSH/config" <<-EOF
# Inserted by prebuild.sh $(date)
Host *
	AddKeysToAgent yes
	UseKeychain yes
	IdentityFile ~/.ssh/$SSH_KEY
EOF

ssh-add -K "$HOME/.ssh/$SSH_KEY"

# https://docs.github.com/en/github/authenticating-to-github/testing-your-ssh-connection
if ! ssh -T git@github.com; then
	echo "Cannot access github, check $SSH_KEY" >&2
	exit 1
fi

if ! mkdir -p "$WS_DIR/git"; then
	echo "Cannot create $WS_DIR/git" .&2
	exit 2
fi

git clone --recurse-submodules "https://github.com/$ORG_DOMAIN/src"

if [[ $USER == rich ]]; then
	./install-1password.sh
fi


if [[ ! $OSTYPE =~ darwin ]] && ! command -v git; then
	apt-get install -y git
fi

"$SOURCE_DIR/bin/install.sh" -u "$GIT_USER" -e "GIT_EMAIL" -r "$DOCKER_USER" -m "$MAIN_EMAIL"
