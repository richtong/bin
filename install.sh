#!/usr/bin/env bash
## vi: se ai sw=4 ts=4 noet :
## The above gets the latest bash on Mac or Ubuntu
##
## This script is designed to run *before* you have the git/src
##
##
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
export REPO_USER="${REPO_USER:-richtong}"
export REPO_DOMAIN="${REPO_DOMAIN:-"tongfamily.com"}"
export REPO_ORG="${REPO_ORG:-"richtong"}"
REPO_EMAIL="${REPO_EMAIL:-"$REPO_USER@$REPO_DOMAIN"}"

USER_ORG="${USER_ORG:-tongfamily}"

DOCKER_INSTALL="${DOCKER_INSTALL:-docker}"
DOCKER_LOGIN="${DOCKER_LOGIN:-true}"
DOCKER_USER="${DOCKER_USER:-richt}"
DOCKER_TOKEN_URI="${DOCKER_TOKEN_URI:-"op://Private/Docker Container Registry - $DOCKER_USER/token"}"
GITHUB_TOKEN_URI="${GITHUB_TOKEN_URI:-"op://Private/Docker Container Registry - $REPO_USER/token"}"

# Note do not use GIT_DIR, this is a defined variable for git
NO_SUDO_PASSWORD="${NO_SUDO_PASSWORD:=false}"
NEW_HOSTNAME="${NEW_HOSTNAME:-"$HOSTNAME"}"
FORCE="${FORCE:-false}"
MAC_SYSTEM_UPDATE="${MAC_SYSTEM_UPDATE:-false}"
WS_DIR="${WS_DIR:-$HOME/ws}"

SSH_USE_KEYCHAIN="${SSH_USE_KEYCHAIN:-false}"
DOTFILES_STOW="${DOTFILES_STOW:-false}"
INSTALL_SECRETS="${INSTALL_SECRETS:-false}"
SECRETS_DIR_ROOT="${SECRETS_DIR_ROOT:-"$HOME/.secret"}"

# deprecated for building machines remotely
DEPLOY_MACHINE="${DEPLOY_MACHINE:-false}"
TESTING_MACHINE="${TESTING_MACHINE:-false}"
ACCOUNTS="${ACCOUNTS:-false}"
# which user is the source of secrets

OPTIND=1
while getopts "a:b:c:def:g:hi:j:k:l:mn:o:p:q:r:s:tu:vw:xy:zD:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Bootstrap script

			usage: $SCRIPTNAME [flags...]

			To bootstrap you should install the base operating system either Mac or Linux

			1. Install brew install git and git-lfs
			2. mkdir ~/ws/git && cd ~/ws/git
			3. git clone https://github.com/$REPO_ORG/src && cd ~/ws/git/src/bin
			4. Run $SCRIPTNAME -h to see what you need

			Debugging flags:
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
				   -h you are reading it now

			Make sure these defaults are correct for your organization:
				   -e Email for user (default: $GIT_EMAIL)
				   -g repo name for github (default: $REPO_ORG)
				   -l Set the name for Logins (default: $REPO_USER)
				   -p Organization path for install (default: $REPO_ORG-install.sh)
				   -u User name for github (default: $GIT_USERNAME)

			Check these as well:
				-a $(! $DOTFILES_STOW && echo "Stow" || echo "Chez-moi") the dotfiles
				-y $(! $SSH_USE_KEYCHAIN && echo "Keychain" || echo "1Password") for ssh keys

			Login to a container registries docker.io and another registry
				   -D docker installation [ docker | colima ] (default: $DOCKER_INSTALL)
				   -k login to all docker container registries (default: $DOCKER_LOGIN)
				   -r dockeR.io user name (default: $DOCKER_USER)
				   -b other container registry url address (default: $OTHER_DOCKER_REGISTRY)
				   -j other container registry user name (default: $OTHER_DOCKER_USER)
				   -q other container registry token (default: $OTHER_DOCKER_TOKEN)

			You should not normally need these:
				   -f $(! $FORCE || echo "do not ") force a git pull of the origin
				   -m $(! $MAC_SYSTEM_UPDATE || echo "do not ")install the MacOS system updates as well
				   -n set the hostname of the system
				   -w the current workspace (default: $WS_DIR)
				   -x $($NO_SUDO_PASSWORD || echo "do not ")require a password when using sudo

			Experimental. Setup of key storage only use if Dropbox has your keys and
			are in a graphical installation does not work from ssh
			and you do not have SSH key forwarding available (experimental)
				   -i use @richtong opininated key storage (default: $INSTALL_SECRETS)
				   -s directory of private keys (default: $SECRETS_DIR_ROOT/$REPO_USER.vc)

			Setup of automated build machines (deprecated)
				   -c $(! DEPLOY_MACHINE && echo "do not ") create a deployment machine
				   -t $(! $TESTING_MACHINE || echo "do not ")create a test machine with unit test and system test
				   -z $(! $ACCOUNTS || echo "do not ")create all the accounts

		EOF

		exit 0
		;;
	d)
		# invert the variable when flag is set and assume -v is on
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;&
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;

	a)
		DOTFILES_STOW="$($DOTFILES_STOW && echo false || echo true)"
		export DOTFILES_STOW
		;;
	b)
		OTHER_DOCKER_REGISTRY="$OPTARG"
		;;
	c)
		DEPLOY_MACHINE="$($DEPLOY_MACHINE && echo false || echo true)"
		ACCOUNTS="$($ACCOUNTS && echo false || echo true)"
		;;
	e)
		GIT_EMAIL="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		;;
	i)
		INSTALL_SECRETS="$($INSTALL_SECRETS && echo false || echo true)"
		;;
	j)
		OTHER_DOCKER_USER="$OPTARG"
		;;
	l)
		REPO_USER="$OPTARG"
		;;
	k)
		DOCKER_USER="$OPTARG"
		;;
	m)
		MAC_SYSTEM_UPDATE=true
		MAC_FLAGS=" -m "
		;;
	n)
		NEW_HOSTNAME="$OPTARG"
		;;
	o)
		DOCKER_LOGIN="$($DOCKER_LOGIN && echo false || echo true)"
		export DOCKER_LOGIN
		;;
	p)
		USER_ORG="$OPTARG"
		;;
	q)
		OTHER_DOCKER_TOKEN="$OPTARG"
		;;
	r)
		DOCKER_USER="$OPTARG"
		;;
	s)
		SECRETS_DIR_ROOT="$OPTARG"
		;;
	t)
		TESTING_MACHINE="$($TESTING_MACHINE && echo false || echo true)"
		ACCOUNTS="$($ACCOUNTS && echo false || echo true)"
		;;
	u)
		GIT_USERNAME="$OPTARG"
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	y)
		SSH_USE_KEYCHAIN="$($SSH_USE_KEYCHAIN && echo false || echo true)"
		export SSH_USE_KEYCHAIN
		;;
	x)
		NO_SUDO_PASSWORD="$($NO_SUDO_PASSWORD && echo false || echo true)"
		;;
	z)
		ACCOUNTS="$($ACCOUNTS && echo false || echo true)"
		;;
	D)
		DOCKER_INSTALL="$OPTARG"
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
source_lib lib-util.sh lib-version-compare.sh lib-git.sh \
	lib-ssh.sh lib-install.sh lib-docker.sh \
	lib-keychain.sh lib-config.sh
shift $((OPTIND - 1))

log_verbose "Run pre-install.sh to get brew and 1Password installed."
log_verbose "pre-install.sh can be run standalone to bootstrap everything"
"$SCRIPT_DIR/pre-install.sh" -g "$REPO_ORG"

log_verbose "setup up bash and zsh profiles basic sourcing and paths"
config_setup

log_verbose "source latest profiles with BASH=$BASH"
source_profile

log_verbose "install brew for linux and mac as common installer"
"$SCRIPT_DIR/install-brew.sh"

log_verbose "install gnu with BASH=$BASH"
"$SCRIPT_DIR/install-gnu.sh"

"$SCRIPT_DIR/install-asdf.sh"

log_verbose "Install git and git tooling"
package_install git
# Install secrets before doing a git

"$SCRIPT_DIR/install-1password.sh"

if $INSTALL_SECRETS; then
	log_verbose "Bailing secrets from veracrypt"
	"$SCRIPT_DIR/install-secrets.sh"
fi

if $SSH_USE_KEYCHAIN; then
	log_verbose "Adding .ssh key passphrases to keychain or keyring"
	"$SCRIPT_DIR/install-ssh-config.sh"
else
	log_verbose "Make sure to enable 1Password"
fi

# Install kubernetes as docker desktop is only a single node
#"$SCRIPT_DIR/install-kubernetes.sh"
# Needed for docker for kubernetes minikube
# "$SCRIPT_DIR/install-xhyve.sh"
# docker or colima installation
if [[ $DOCKER_INSTALL =~ docker ]]; then
	if ! "$BIN_DIR/install-docker.sh"; then
		log_exit 0 "need to logout and return to get into the docker group"
	fi
else
	"$BIN_DIR/install-docker-alternative.sh" -c
fi

log_verbose "Multiple login to all container registries with -a"
"$BIN_DIR/login-container-registry.sh"

# install-git-tools needs python
log_verbose "installing python"
"$SCRIPT_DIR/install-python.sh"

# the {-} means replace with null if FORCE_FLAG is not set
log_verbose "Installing git tools"
"$SCRIPT_DIR/install-git-tools.sh" -u "$REPO_USER" -e "$REPO_EMAIL"
log_verbose must be installed is git lfs is used before installing repos
"$BIN_DIR/install-git-lfs.sh"
log_verbose install repos only if not in docker

# now assume we are installing src, src/bin and src/lib
# if ! in_os docker &&
#	"$SCRIPT_DIR/install-repos.sh" "${FORCE_FLAG-}"; then
#	log_warning "install-repos.sh returned $?"
#fi

# run dotfiles-stow as soon as possible use the personal repo above
# Otherwise the installation scripts below will cause conflicts
# Starting to replace rich's fine dotfiles with chezmoi.io
if $DOTFILES_STOW; then
	log_verbose "put into .bak all files that need to be stowed"
	"$SCRIPT_DIR/dotfiles-backup.sh"
	log_verbose "install dotfiles note that this needs the personal repo installed to work"
	"$SCRIPT_DIR/dotfiles-stow.sh"
	log_verbose "in the stow process if .ssh is touched the permissions will be too wide"
else
	"$SCRIPT_DIR/install-chezmoi.sh"
fi

# install this after you stow
log_verbose "Install Zsh options"
"$SCRIPT_DIR/install-zsh.sh"

# https://unix.stackexchange.com/questions/129143/what-is-the-purpose-of-bashrc-and-how-does-it-work
# https://stackoverflow.com/questions/9953005/should-the-bashrc-in-the-home-directory-load-automatically
# macOS defaults: interactive login shell: /etc/profile ->
#										   first[~/.bash_profsle, ~/.bash_login ~/.profile] ->
#										   ~/.bashrc
#				  interactive non-login shell: ~/.bashrc -> /etc/ashrc
#				  logout shell: ~/.bash_logout
#
# https://www.stefaanlippens.net/bashrc_and_others/
# login shell means you login directly like an ssh session
# non-login shell is a new terminal windows from iterm2
#
# So what do I put in which file:
# .profile:  for non-Bash related environment variables.
# .bash_profile: for the first login and it sets things that are inherited to non-interactive shells
# .bashrc - for interactive things like alias that do not get inherited

# https://www.computerhope.com/unix/bash/shopt.htm
# globstart ls **/.profile matches all directoris in the path
# nullglob: is * doesn't match it is turned into an empty string
# https://stackoverflow.com/questions/24173875/is-there-a-way-to-export-bash-shell-options-to-subshell
log_verbose "Add to .bashrc parameters not inherited from login shell"
if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-'EOF'
		set -o vi
		shopt -s autocd cdspell cdable_vars checkhash checkjobs \
				checkwinsize cmdhist direxpand dirspell dotglob \
				extglob globstar nullglob
	EOF
fi

if ! config_mark; then
	config_add <<-'EOF'
		# this runs everytime on login and for each interactive shell Mac Terminal
		# creates. Chains to ~/.bashrc for aliases what needs to run on each subshell
		# shellcheck disable=SC1091
		if echo "$BASH" | grep -q "bash" && [ -f "$HOME/.bashrc" ]; then . "$HOME/.bashrc"; fi
	EOF
fi

"$SCRIPT_DIR/install-go.sh"

log_warning mac-install.sh must be run first before sourcing libraries
# These are set later as they depend on variables that can be
# positional parameters

# No long use these entries instead all keys are used and config file
# FULL_GIT_KEY="$REPO_USER@$GIT_KEY"
# FULL_LOCAL_KEY="$REPO_USER@$LOCAL_KEY"
# log_verbose assembling the full git key as $FULL_GIT_KEY and $FULL_LOCAL_KEY
# the installation of packages

if in_os linux; then
	log_verbose "checking if this is bare metal linux"
	"$SCRIPT_DIR/linux-install.sh"

fi

log_verbose "Install markdown and mkdocs tools"
"$BIN_DIR/install-mkdocs.sh"
# deprecated Sphinx use Markdown
# "$SCRIPT_DIR/install-sphinx.sh"
"$SCRIPT_DIR/install-markdown.sh"
if [[ $OSTYPE =~ darwin ]]; then
	log_verbose "mac-install.sh with ${MAC_FLAGS-no flags}"
	"$SOURCE_DIR/bin/mac-install.sh" "${MAC_FLAGS-}"
	# to get the latest mac ports, need to source the new .profile
	# note make sure that things like :ll
	source_profile
	log_verbose "using bash at $(command -v bash)"
fi

mkdir -p "$WS_DIR"

# common packages

# bfg - remove passwords and big files you didn't mean to commit this is snap only
# curl - not clear if needed but MacOS doesn't have the latest
# fzf - fast search for directories etc.
# gh - github cli
# mandoc - To get the version with man --path
# ripgrep - way better grepping
# sudo - Linux only
# lua - for lib-config.sh and neovim
# luarocks - lua package manager
# stylua - style checker for lua

PACKAGES+=(

	bashdb
	curl
	font-alegreya-sc
	font-source-serif-pro
	fzf
	golang
	lua
	luarocks
	stylua
	graphviz
	mandoc
	mmv
	pre-commit
	ripgrep

)

if ! in_os mac; then
	log_verbose "install linux packages"
	PACKAGES+=(uuid-runtime)
	# qemu-user-static allows qemu to run non-Intel binaries as does bin-fmt-supprt
	# ppa-purge to remove ubuntu repos
	# v4l-utils for usb cameras
	PACKAGES+=(qemu-user-static binfmt-support v4l-utils)
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

	if ! in_wsl; then
		log_verbose "install snap packages only in real linux not in wsl"
		# https://snapcraft.io/install/bfg-repo-cleaner/ubunt-
		sudo snap install bfg-repo-cleaner --beta
	fi

fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing ${PACKAGES[*]}"
if [[ -v PACKAGES ]]; then
	package_install "${PACKAGES[@]}"
fi

# currently no python packages are needed
log_verbose "installing python packages ${PYTHON_PACKAGES[*]} in user mode and upgrade dependencies"
if [[ -v PYTHON_PACKAGES ]]; then
	# pip_install --user --upgrade "${PYTHON_PACKAGES[@]}"
	pipx_install "${PYTHON_PACKAGES[@]}"
fi

# https://kislyuk.github.io/argcomplete/ for pytest
log_verbose "complete argcomplete parse"
# this is not found in the instalation
#activate-global-python-argcomplete

log_verbose "installing development and devops systems"
"$SCRIPT_DIR/install-node.sh"
"$SCRIPT_DIR/install-google-cloud-sdk.sh"
"$SCRIPT_DIR/install-jupyter.sh"
"$SCRIPT_DIR/install-google-chrome.sh"

"$SCRIPT_DIR/install-ssh.sh"
log_verbose Also allow ssh into this machine so you can switch to using consoler
if [[ $OSTYPE =~ darwin ]]; then
	systemsetup -setremotelogin on
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
# install nvidia and cuda
"$SCRIPT_DIR/install-nvidia.sh"

log_verbose check for various wifi adapters
"$SCRIPT_DIR/install-dwa182.sh"
"$SCRIPT_DIR/install-bcm4360.sh"
"$SCRIPT_DIR/install-bcm43228.sh"

log_verbose install linters
"$SCRIPT_DIR/install-lint.sh"

# need to make sure we quoting correctly as bash version contains parentheses
# Bump now using bash version 5
log_assert "bash --version | awk 'NR==1 {print \$4}' | grep -q '^[45]'" "bash version 4 detected"
# This script can run in Bash 3, but you need to make sure that all the
if [[ $BASH_VERSION != 4* || $BASH_VERSION != 5* ]]; then
	log_warning "$SCRIPTNAME running $BASH_VERSION but subscripts running in $(bash --version | head -1)"
fi

log_verbose "Installing fonts"
"$BIN_DIR/install-fonts.sh"

# deprecated now use config_setup to do the same thing
# if ! "$SCRIPT_DIR/set-profile.sh"; then
# log_warning
# fi
log_verbose "source profiles in case we did not reboot"
source_profile

log_verbose "Install organization specific componenets for $USER_ORG if any"
run_if "$SCRIPT_DIR/$USER_ORG-install.sh"

# Assumes that personal.git is at the same level as src
log_verbose Chain to your personal installs
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
run_if "$SOURCE_DIR/user/$REPO_USER/bin/user-install.sh" "$@"

log_verbose "Now chain to .rc"
config_setup_end

# log_verbose update all submodules only for special use cases
# "$SOURCE_DIR/scripts/build/update-all-submodules.sh"

# This next section is for linux only
if [[ $OSTYPE =~ darwin ]]; then
	log_exit "mac finished"
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
