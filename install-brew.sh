#!/usr/bin/env bash
## Install [Homebrew](https://brew.sh)
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
HOMEBREW_USER="${HOMEBREW_USER:-"$USER"}"
while getopts "hdvu:" opt; do
	case "$opt" in
	h)
		cat <<EOF
        $SCRIPTNAME: Install homebrew
        flags: -h help
               -d $(! $DEBUGGING || echo "no ")debugging
               -v $(! $VERBOSE || echo "not ")verbose
               -u homebrew must have a single user (default: $HOMEBREW_USER)
EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	u)
		HOMEBREW_USER="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-util.sh lib-config.sh lib-install.sh

if command -v brew >/dev/null; then
	log_exit "brew already installed"

# https://apple.stackexchange.com/questions/175069/how-to-accept-xcode-license
elif in_os linux || in_os wsl-linux; then
	log_verbose "installing linuxbrew"
	package_install build-essential curl file git

	log_verbose "Need all users in the same group to share /home/linuxbrew"
	log_verbose "In MacOS all users are in staff so they can share brew and umask is 022"
	# https://superuser.com/questions/20420/what-is-the-difference-between-the-default-groups-on-mac-os-x
	# https://superuser.com/questions/20420/what-is-the-difference-between-the-default-groups-on-mac-os-x
	log_verbose "but in Linux, users are in private groups so check umask is 002"
	if [[ $USER == "$GROUP" ]] && (($(umask) > 2)); then
		log_error "Using private groups and umask must be set to 002"
	fi

	bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

	# this is moved to lib-install.sh
	#if ! config_mark "$(config_profile_shell_bash)"; then
	#config_add "$(config_profile_shell_bash)" <<-'EOF'
	#test for variable in case other apps override homebrew
	#[[ -v HOMEBREW_PREFIX ]] || eval $($HOMEBREW_PREFIX/bin/brew shellenv)
	#EOF
	#fi
	#homebrew_completion
	brew_profile_install
	# this is not needed since source_profile will get this
	#test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
	#test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	#test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
	source_profile

elif in_os mac; then
	log_verbose "Install Mac Homebrew"
	xcode_license_accept
	# since High Sierra /usr/local/sbin for system bin that is files
	# not user accessible but used by utilities like unbound a dns
	# resolver that opencv uses
	# https://github.com/Homebrew/homebrew-php/issues/4527

	# breew requires xcode
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

	# add profile
	brew_profile_install
	source_profile

	SBIN="${SBIN:-"$(brew --prefix)/sbin"}"
	log_verbose "creating $SBIN if needed"
	if [[ ! -e $SBIN ]]; then
		# only use sudo if necessary
		$(config_sudo "$SBIN") mkdir -p "$SBIN"
	fi
	log_verbose "adding $SBIN to the profile if needed"
	#if ! config_mark; then
	# this no longer seems to work in Bash 5.0
	# config_add <<<"export PATH+=:/usr/local/sbin"
	#homebrew_completion
	#fi
	#if ! config_mark "$(config_profile)"; then
	#    config_add "$(config_profile)" <<-'EOF'
	#        # add the check because asdf and pipenv override homebrew
	#                if command -v brew >/dev/null && [[ ! $PATH =~ $(brew --prefix) ]]; then eval "$(brew shellenv)"; fi
	#    EOF
	#fi
	# make sure we can write the brew files you can have access problems
	# If another user uses brew
	# https://ubuntuforums.org/showthread.php?t=439610
	# https://gist.github.com/jaibeee/9a4ea6aa9d428bc77925
	#
	# This doe not completely work to change permissions because touch
	# is used by home brew and you can only touch files that you own.
	# Only solution appears to be to only allow a single user
	# to use homebrew
	# https://discourse.brew.sh/t/homebrew-permissions-for-multiple-users/686
	# the recommendation is to create a dedicated 'brew' user and use sudo -u brew
	# We take the easier way out and just chown to the current user
	HOMEBREW_DIRS="${HOMEBREW_DIRS:-"
		Cellar
		Homebrew
		Frameworks
		share
		lib
		etc
		sbin
	"}"
	for f in $HOMEBREW_DIRS; do
		log_verbose "checking $HOMEBREW"
		file="$(brew --prefix)/$f"
		if [[ ! -e $file ]]; then
			log_verbose "$file does not exist skipping"
			mkdir -p "$file"
		fi
		# https://apple.stackexchange.com/questions/130685/understanding-the-staff-user-group
		members="$(dscacheutil -q group -a name "$(util_group "$file")" | grep ^users: | awk '{$1= ""; print $0}')"
		log_verbose "$members can access $file"
		if [[ $members =~ $USER ]]; then
			sudo chmod -R g+w "$file"
			log_verbose "cannot write to $file as user but made group writeable"
		fi
		log_verbose "need to change these to your $HOMEBREW_USER"
		sudo find "$file" \! -user "$HOMEBREW_USER" -a \! -type l -exec chown "$HOMEBREW_USER" {} \;
	done
	# https://github.com/Homebrew/homebrew-cask/issues/58046
	log_verbose "Make sure depend_on references are moved"
	find "$(brew --prefix)/Caskroom/"*'/.metadata' -type f -name '*.rb' -print0 | /usr/bin/xargs -0 /usr/bin/perl -i -pe 's/depends_on macos: \[.*?\]//gsm;s/depends_on macos: .*//g'

else
	log_exit "Do not now how to install in this os"

fi

log_assert "command -v brew > /dev/null" "brew installed"

log_verbose "make sure brew is up to date"
brew update
log_verbose "make sure brew takes over all packages it owns with --greedy"
brew upgrade --greedy

log_verbose "bash completion added to profile"
"$SCRIPT_DIR/install-bash-completion.sh"
