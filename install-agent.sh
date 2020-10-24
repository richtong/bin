#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## Installs all the configuration needed for an unattended agent
## Assumes that install-accounts.sh and install-agents.sh has been run
## which configures the overall account and ssh keys.
## And that the private keys are already properly copied into the ~/.ssh
## directory
##
## also looks for a lib-keychain.sh to get ssh key access
##
## This runs on the local machine in the agent's account with limited privileges
## This avoids needing to give sudo access to an agent.
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"}
OPTIND=1
while getopts "hdvw:u:e:w:k:r:m:l:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: setup an individual agent account in agent context"
		echo "flags: -d debug, -h help -v verbose"
		echo " -u git User name"
		echo " -e Email use for git"
		echo " -r dockeR user name"
		echo " -m eMail for docker"
		echo " -w wsdir"
		echo " -k ssh key to github"
		echo " -l ssh key for local machines"
		echo " -x no sudo password"
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
		DOCKER_EMAIL="$OPTARG"
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	k)
		GIT_KEY="$OPTARG"
		;;
	l)
		LOCAL_KEY="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-version-compare.sh lib-git.sh lib-keychain.sh

# The default is ws and others, you can either set in flags
# Or as shell variables exported
# For whatever reason you must use $HOME here and not ~ even though
# test works in interactive bash but won't work in a script
# We are using ssh so these paths are all relative to $USER's home directory
export SOURCE_DIR="$WS_DIR/git/src"
# Note do not use GIT_DIR, this is a defined variable for git that is the # current repo
ORG_NAME="${ORG_NAME:-"tongfamily"}"
ORG_DOMAIN="${ORG_DOMAIN:-"$ORG_NAME.com"}"
GIT_USER=${GIT_USER:="$ORG_NAME-$USER"}
GIT_EMAIL=${GIT_EMAIL:="$USER@$ORG_DOMAIN"}
DOCKER_USER=${DOCKER_USER:-"$ORG_NAME$USER"}
DOCKER_EMAIL=${DOCKER_EMAIL:-"$GIT_EMAIL"}
GIT_KEY=${GIT_KEY:="$GIT_EMAIL-github.com.id_ed25519"}
LOCAL_KEY=${LOCAL_KEY:-"$DOCKER_EMAIL-$ORG_DOMAIN.id_ed25519"}

# do not shift, pass this onto install.sh
# shift $((OPTIND-1))

# now we can check for unbound variables
set -u

if $VERBOSE; then
	echo >&2 "$SCRIPTNAME: $USER repo $WS_DIR"
	echo >&2 "      git $GIT_USER ($GIT_EMAIL)"
	echo >&2 "      docker $DOCKER_USER ($DOCKER_EMAIL)"
fi

mkdir -p "$WS_DIR"

# Make sure we are using the correct keychain as gnome doesn't handle id_25519 keys
if ! use_openssh_keychain "$GIT_KEY" "$LOCAL_KEY"; then
	log_error 3 "added openssh keychain, reboot required then restart script"
fi

log_verbose set profile using the Dropbox secrets
if "$SCRIPT_DIR/set-profile.sh" -s "$HOME"; then
	log_error 4 "updated configuration, please reboot and restart this script"
fi

if ! "$BIN_DIR/install-git-and-repos.sh" -u "$GIT_USER" -e "$GIT_EMAIL" -k "$GIT_KEY"; then
	log_error 6 "could not setup repos"
fi

# If there are other agent specific installations they go in personal
if [ -f "$WS_DIR/git/user/agent/bin/install.sh" ]; then
	# pass on the argument so make sure install.sh uses the same
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	"$WS_DIR/git/user/agent/bin/install.sh" -m "$DOCKER_EMAIL" -r "$DOCKER_USER" "$@"
fi
