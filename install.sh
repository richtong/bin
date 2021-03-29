#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
## This script is designed to run *before* you have the git/src
## Uses Dropbox to get private keys from ecryptfs Private
##
## vi: se et ai sw=4 :
##
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
export SCRIPTNAME
# need to use trap and not -e so bashdb works
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
export REPO_USER="${REPO_USER:-"$USER"}"
export REPO_DOMAIN="${REPO_DOMAIN:-"tongfamily.com"}"
export GIT_REPO_NAME="${GIT_REPO_NAME:-"richtong"}"

export DOCKER_USER="${DOCKER_USER:-"$REPO_USER"}"
export GIT_USERNAME="${GIT_USERNAME:-"${REPO_USER^}"}"

# Note do not use GIT_DIR, this is a defined variable for git
export GIT_EMAIL="${GIT_EMAIL:-"$REPO_USER@$REPO_DOMAIN"}"
NO_SUDO_PASSWORD="${NO_SUDO_PASSWORD:=false}"
NEW_HOSTNAME="${NEW_HOSTNAME:-"$HOSTNAME"}"
DOTFILES_STOW="${DOTFILES_STOW:-false}"
FORCE="${FORCE:-false}"
MAC_SYSTEM_UPDATE="${MAC_SYSTEM_UPDATE:-false}"
WS_DIR="${WS_DIR:-$HOME/ws}"

INSTALL_SECRETS="${INSTALL_SECRETS:-false}"
export SECRETS_DIR_ROOT="${SECRETS_DIR_ROOT:-"/Volumes"}"
# override if in linux
if [[ ! $OSTYPE =~ darwin ]]; then
	export SECRETS_DIR_ROOT="${SECRETS_DIR_ROOT:-"/media"}"
fi

# deprecated for building machines remotely
DEPLOY_MACHINE="${DEPLOY_MACHINE:-false}"
TESTING_MACHINE="${TESTING_MACHINE:-false}"
ACCOUNTS="${ACCOUNTS:-false}"
# which user is the source of secrets

OPTIND=1
while getopts "hdvu:e:r:a:fw:n:xmi:s:l:c:tz" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Bootstrap script

			usage: $SCRIPTNAME [flags...]

			To bootstrap you should install the base operating system either Mac or Linux

			1. Install git
			2. mkdir ~/ws/git && cd ~/ws/git  && git clone https://github.com/GIT_REPO/src
			3. cd ~/ws/git/src/bin and Run $SCRIPTNAME -h to see what you need
			4. Get a login to docker and set your docker user name
			3. Now run $SCRIPTNAME with these available flags

			Make sure these defaults are correct:
			       -o The dOmain name (default: $REPO_DOMAIN)
			       -l Set the name for Logins (default: $REPO_USER)
			       -e rEpo name for github (default: $GIT_REPO_NAME)
			       -r dockeR user name (default: $DOCKER_USER)

			Check these as well:
			       -e Email for user (default: $GIT_EMAIL)
			       -u User name for github (default: $GIT_USERNAME)
			       -a Use dotfiles stow to hive away your dotfiles in the repo (default:
			$DOTFILES_STOW)

			You should not normally need these:
			       -f force a git pull of the origin (default: $FORCE)
			       -w the current workspace (default: $WS_DIR)
			       -n set the hostname of the system
			       -x do not require a password when using sudo (default: $NO_SUDO_PASSWORD)
			       -m install the MacOS system updates as well (default: $MAC_SYSTEM_UPDATE)

			Experimental. Setup of key storage only use if Dropbox has your keys and
			are in a graphical installation does not work from ssh
			and you do not have SSH key forwarding available (experimental)
			       -i use @richtong opininated key storage (default: $INSTALL_SECRETS)
			       -s directory of private keys (default: $SECRETS_DIR_ROOT/$REPO_USER.vc)

			Setup of automated build machines (deprecated)
			       -c creates a deployment machine (default: $DEPLOY_MACHINE)
			       -t creates a test machine with unit test and system test (default: $TESTING_MACHINE)
			       -z create all the accounts deprecated (default: $ACCOUNTS)

			Debugging flags:
			        -v verbose output for script
			        -d single step debugging
			        -h you are reading it now
		EOF

		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	l)
		REPO_USER="$OPTARG"
		;;
	u)
		GIT_USERNAME="$OPTARG"
		;;
	e)
		GIT_EMAIL="$OPTARG"
		;;
	r)
		DOCKER_USER="$OPTARG"
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	s)
		SECRETS_DIR_ROOT="$OPTARG"
		;;
	a)
		DOTFILES_STOW=true
		;;
	x)
		NO_SUDO_PASSWORD=true
		;;
	c)
		DEPLOY_MACHINE=true
		ACCOUNTS=true
		;;
	t)
		TESTING_MACHINE=true
		ACCOUNTS=true
		;;
	n)
		NEW_HOSTNAME="$OPTARG"
		;;
	i)
		INSTALL_SECRETS=true
		;;
	m)
		MAC_SYSTEM_UPDATE=true
		MAC_FLAGS=" -m "
		;;
	f)
		FORCE=true
		;;
	z)
		ACCOUNTS=true
		;;
	*)
		echo "$opt not valid"
		;;
	esac
done
# https://github.com/koalaman/shellcheck/wiki/SC1090
# does not work in vi
# shellcheck source=include.sh
# disable following source
# shellcheck disable=SC1091
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
log_verbose "WS_DIR is $WS_DIR"
source_lib lib-util.sh lib-version-compare.sh lib-git.sh \
	lib-ssh.sh lib-install.sh lib-docker.sh \
	lib-keychain.sh lib-config.sh
shift $((OPTIND - 1))

# do not use config_add because this added the comment line
log_verbose "Add #! to profiles"
for profile in "$(config_profile)" "$(config_profile_shell)"; do
	if [[ ! -e $profile ]]; then
		echo '#!/usr/bin/env bash' >>"$profile"
	fi
done

# https://unix.stackexchange.com/questions/129143/what-is-the-purpose-of-bashrc-and-how-does-it-work
if ! config_mark; then
	config_add <<-'EOF'
		# shellcheck disable=SC2016
		if [[ -e $HOME/.bashrc ]]; then source "$HOME/.bashrc"; fi
	EOF
fi

if [[ $OSTYPE =~ darwin ]]; then
	log_verbose "mac-install.sh with ${MAC_FLAGS-no flags}"
	"$SOURCE_DIR/bin/mac-install.sh" "${MAC_FLAGS-}"
	# to get the latest mac ports, need to source the new .profile
	source_profile
	log_verbose "using bash at $(command -v bash)"
fi

log_warning mac-install.sh must be run first before sourcing libraries
# These are set later as they depend on variables that can be
# positional parameters

# No long use these entries instead all keys are used and config file
# FULL_GIT_KEY="$REPO_USER@$GIT_KEY"
# FULL_LOCAL_KEY="$REPO_USER@$LOCAL_KEY"
# log_verbose assembling the full git key as $FULL_GIT_KEY and $FULL_LOCAL_KEY
# the installation of packages

if [[ $OSTYPE =~ linux ]]; then

	log_verbose install check for sudo
	# lua used by lib-config
	package_install sudo lua5.2
	log_verbose check for sudo

	log_verbose Adding sudoers entry ignored if running under iam-key
	SUDOERS_FILE="/etc/sudoers.d/10-$USER"
	if [[ "$NO_SUDO_PASSWORD" == true ]]; then
		log_verbose trying to remove need for sudo password
		if ! groups | grep sudo || [[ ! -e "$SUDOERS_FILE" ]]; then
			log_warning no sudo available please enter root password
			# note we need to escape the here document quotes so they
			# get passed to su and also around the file name
			su -c "tee \"$SUDOERS_FILE\" <<<\"$USER ALL=(ALL:ALL) NOPASSWD:ALL\" && \
               chmod 440 \"$SUDOERS_FILE\""
		fi
	fi

	log_verbose checking if this is bare metal linux
	if in_os linux; then
		log_verbose configure linux for bootstrap debug
		"$SCRIPT_DIR/install-linux-debug.sh"
	fi

	# surround.io only
	# log_verbose check for vmware
	# "$SCRIPT_DIR/install-vmware-tools.sh"
	# the first number indicates priority, make account sudo-less
	# "$SCRIPT_DIR/install-iam-key-daemon.sh"

	# Per http://unix.stackexchange.com/questions/9940/convince-apt-get-not-to-use-ipv6-method
	if ! sudo touch /etc/apt/apt.conf.d/99force-ipv4; then
		echo "$SCRIPTNAME: Could not create 99force-ipv4"
	elif ! grep "^Acquire::ForceIPv4" /etc/apt/apt.conf.d/99force-ipv4; then
		sudo tee -a /etc/apt/apt.conf.d/99force-ipv4 <<<'Acquire::ForceIPv4 "true";'
	fi

	# Problems here include internet not up or the dreaded Hash Mismatch
	# This is usually due to bad ubuntu mirrors
	# See # http://askubuntu.com/questions/41605/trouble-downloading-packages-list-due-to-a-hash-sum-mismatch-error
	if ! sudo apt-get -y update; then
		echo "$SCRIPTNAME: apt-get update failed with $?"
		echo "  either no internet or a bad ubuntu mirror"
		echo "  retry or sudo rm -rf /var/list/apt/lists* might help"
		exit 4
	fi

	sudo apt-get -y upgrade

	# not this should no longer exist now that we are on docker
	run_if "$SOURCE_DIR/scripts/build/install-dev-packages.sh"
	# The new location for boot strap file and the Mac section below should do
	# it all
	run_if "$SOURCE_DIR/scripts/build/bootstrap-dev"
fi

mkdir -p "$WS_DIR"
if $FORCE; then
	FORCE_FLAG="-f"
fi

log_verbose install secrets will work with ssh now that we can use dropbox cli
if $INSTALL_SECRETS; then
	# no longer load dropbox where secrets are stored note this currently graphical
	"$SCRIPT_DIR/install-google.sh"
	# "$SCRIPT_DIR/install-dropbox.sh"

	log_verbose install secrets from veracrypt and link to .ssh
	"$SCRIPT_DIR/install-secrets.sh" -u "$REPO_USER" -r "$SECRETS_DIR_ROOT"
fi

"$BIN_DIR/install-anaconda.sh"
PYTHON_PACKAGES=(
)

# these python packages do not always install command line argument stuff

# common packages
# mmv - multiple file move and rename
# curl - not clear if needed but MacOS doesn't have the latest
# bfg - remove passwords and big files you didn't mean to commit
# sudo - Linux only
PACKAGES+=(
	mmv
	curl
	bfg
	git
	pre-commit
)

if ! in_os mac; then
	log_verbose install linux packages
	# qemu-user-static let's docker run arm containers
	# note that bootstrap-dev now install python-pip and python-yaml and uuid-runtime
	# but we repeat here so not dependent on bootstrap-dev
	PACKAGES+=(uuid-runtime python3-pip python-yaml)
	# qemu-user-static allows qemu to run non-Intel binaries as does bin-fmt-supprt
	# ppa-purge to remove ubuntu repos
	# v4l-utils for usb cameras
	# only needed for surround.io
	# PACKAGES+=" qemu-user-static binfmt-support v4l-utils "
	# This needs to be installed before docker-py which is no longer needed
	# PYTHON_PACKAGES+=" requests[security] "
	# find members of a group needed by ZFS tools
	PACKAGES+=(members)
	# password generator
	PACKAGES+=(pwgen)

	# Note that http://stackoverflow.com/questions/29099404/ssl-insecureplatform-error-when-using-requests-package
	# So this docker-py used to requires requests[security]
	# name also changed to just docker
	log_verbose "no pip install docker install docker-py instead"
	log_verbose if you mistakely install docker, you need to remove both docker and docker-py
	log_verbose before installing docker-py again

fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing ${PACKAGES[*]}"
if [[ -v PACKAGES ]]; then
	package_install "${PACKAGES[@]}"
fi

# currently no python packages are needed
log_verbose "installing python packages ${PYTHON_PACKAGES[*]} in user mode and upgrade dependencies"
if [[ -v PYTHON_PACKAGES ]]; then
	pip_install --user --upgrade "${PYTHON_PACKAGES[@]}"
fi

# https://kislyuk.github.io/argcomplete/ for pytest
log_verbose "complete argcomplete parse"
# this is not found in the instalation
#activate-global-python-argcomplete

log_verbose "installing development and devops systems"
"$SCRIPT_DIR/install-node.sh"
"$SCRIPT_DIR/install-gcloud.sh"
"$SCRIPT_DIR/install-netlify.sh"
"$SCRIPT_DIR/install-terraform.sh"
"$SCRIPT_DIR/install-jupyter.sh"
"$SCRIPT_DIR/install-ruby.sh"
"$SCRIPT_DIR/install-1password.sh"

log_verbose "skipping install-flutter but somehow"
#"$SCRIPT_DIR/install-flutter.sh"

log_verbose install brew for linux and mac
"$SCRIPT_DIR/install-brew.sh"

# the {-} means replace with null if FORCE_FLAG is not set
"$SCRIPT_DIR/install-git-tools.sh" -u "$GIT_USERNAME" -e "$GIT_EMAIL"
log_verbose must be installed is git lfs is used before installing repos
"$BIN_DIR/install-lfs.sh"

log_verbose install repos only if not in docker
if ! in_os docker &&
	"$SCRIPT_DIR/install-repos.sh" ${FORCE_FLAG-}; then
	log_warning "install-repos.sh returned $?"
fi

# run dotfiles-stow as soon as possible use the personal repo above
# Otherwise the installation scripts below will cause conflicts
if $DOTFILES_STOW; then
	log_verbose put into .bak all files that need to be stowed
	"$SCRIPT_DIR/dotfiles-backup.sh"
	log_verbose install dotfiles note that this needs the personal repo installed to work
	"$SCRIPT_DIR/dotfiles-stow.sh"
	"$SCRIPT_DIR/fix-ssh-permissions.sh"
	log_verbose in the stow process if .ssh is touched the permissions will be too wide
fi

log_verbose Also allow ssh into this machine so you can switch to using consoler
if [[ $OSTYPE =~ darwin ]]; then
	systemsetup -setremotelogin on
else
	"$SCRIPT_DIR/install-openssh-server.sh"
fi
log_verbose ssh has now been installed and iam-key server as well
log_verbose you can now quit this and run the rest via ssh
log_verbose and use ssh key forwarding to handle credentials

if [[ $OSTYPE =~ darwin ]]; then
	log_verbose mac post installation for things that need ssh keys
	log_verbose runs after the stow so that dotfiles are not overwritten

fi

# Now installed by bootstrap-dev but no harm to run again
log_verbose install nvidia
"$SCRIPT_DIR/install-nvidia.sh"
log_verbose to install cuda run "$SCRIPT_DIR/install-cuda.sh"

log_verbose check for various wifi adapters
"$SCRIPT_DIR/install-dwa182.sh"
"$SCRIPT_DIR/install-bcm4360.sh"
"$SCRIPT_DIR/install-bcm43228.sh"

log_verbose install linters
"$SCRIPT_DIR/install-lint.sh"

# need to make sure we quoting correctly as bash version contains parentheses
# Bump now using bash version 5
log_assert "bash --version | awk 'NR==1 {print \$4}' | grep -q ^[45]" "bash version 4 detected"
# This script can run in Bash 3, but you need to make sure that all the
if [[ $BASH_VERSION != 4* || $BASH_VERSION != 5* ]]; then
	log_warning "$SCRIPTNAME running $BASH_VERSION but subscripts running in $(bash --version | head -1)"
fi

# docker is the lowest level, so install first
# These are clones from src/infra/docker files
if ! "$BIN_DIR/install-docker.sh"; then
	log_warning "need to logout and return to get into the docker group"
	exit 0
fi

if [[ ! -e $HOME/.docker/config.json ]] || ! grep -q auth "$HOME/.docker/config.json"; then
	"$BIN_DIR/docker-login.sh" -u "$DOCKER_USER"
fi

if ! "$SCRIPT_DIR/set-profile.sh"; then
	log_verbose profile changes so source needed
fi
log_verbose source profiles in case we did not reboot
source_profile

# install sphinx for documentation swap to markdown
# "$SCRIPT_DIR/install-sphinx.sh"
"$SCRIPT_DIR/install-markdown.sh"

# Assumes that personal.git is at the same level as src
log_verbose Chain to your personal installs
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
run_if "$SOURCE_DIR/user/$REPO_USER/bin/install.sh" "$@"

# log_verbose update all submodules only for special use cases
# "$SOURCE_DIR/scripts/build/update-all-submodules.sh"

# This next section is for linux only
if [[ $OSTYPE =~ darwin ]]; then
	exit 0
fi

log_verbose set hostname if needed
if [[ $NEW_HOSTNAME != "$HOSTNAME" ]]; then
	"$SCRIPT_DIR/set-hostname.sh" -f "$NEW_HOSTNAME"
	exit 4
fi

if ! groups | grep docker; then
	if sudo service iam-key status | grep -q running; then
		log_warning "$USER is not in group docker"
		log_warning edit the /etc/opt/tongfamily/iam-key.conf.yml to allow docker
		log_warning and also sudo, sudonopass and sambashare
		log_warning afterwards run sudo service iam-key restart
		log_warning and check that it worked with journalctld -xe | grep iam
		log_warning and the logout to have groups take effect
	else
		log_warning not in docker group, logout and return to this script
	fi
	log_error 1 "not in docker group"
fi

# Goodsync introduces a non-portable issue. On Mac OS X, you can have a space in
# a path name, but w-enable-docker barfs on it
# This intense like use \( \) to group parts of regex lookf or spaces
# not prefixed by a backslash and adds them
log_verbose fixup PATH to never have a space by itself
for profile in "$HOME/.bash_profile" "$HOME/.profile" "$HOME/.bashrc"; do
	if [[ -e $profile ]]; then
		sed -i 's/\(^PATH=\).*\([^\\]\)\( \)/\\&2/g' "$profile"
	fi
done

# log_verbose enable docker
# log_verbose if you wnat to run wscons then run "$SOURCE_DIR/local-bin/w-enable-docker"
# log_verbose "$SOURCE_DIR/local-bin/wscons pre" for unit tests
# log_verbose "$SOURCE_DIR/local-bin/wvrun"

log_verbose either logout and login or source "$HOME/.profile" to get development command
# deprecated, but you can setup machines if you want

# First way is to use conditional if
# http://wiki.bash-hackers.org/syntax/pe#use_an_alternate_value
# if variable is unset then it is nothing otherwise send a flag
# sending via flags but does not work if ACCOUNTS for instance
# set to false, so this only works if false is really an unset
#"$SOURCE_DIR/install-machines.sh" ${ACCOUNTS:+"-a"} \
#                                  ${DEPLOY_MACHINE:+"-x"} \
#                                  ${TESTING_MACHINE:+"-t"}
# alternate way to set variables

if [[ -n $ACCOUNTS || -n $DEPLOY_MACHINE || -n $TESTING_MACHINE ]]; then
	export ACCOUNTS DEPLOY_MACHINE TESTING_MACHINE
	"$SCRIPT_DIR/install-machines.sh"
	export -n ACCOUNTS DEPLOY_MACHINE TESTING_MACHINE
fi

log_warning to get the correct path, either source ~/.profile or logout
