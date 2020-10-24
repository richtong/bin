#!/usr/bin/env bash
##
## Install [Homebrew](https://brew.sh)
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
HOMEBREW_USER="${HOMEBREW_USER:-"$USER"}"
while getopts "hdvu:" opt; do
	case "$opt" in
	h)
		cat <<EOF
$SCRIPTNAME: Install homebrew

        flags: -d debug, -h help -v verbose
               -u homebrew must have a single user (default: $HOMEBREW_USER)

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

if command -v brew; then
	log_exit brew already installed
fi

if ! in_os mac; then
	log_verbose installing linuxbrew
	package_install build-essential curl file git
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
	test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
	test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
	echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
	log_exit "Linux brew installed"
fi

# since High Sierra /usr/local/sbin for system bin that is files
# not user accessible but used by utilities like unbound a dns
# resolver that opencv uses
# https://github.com/Homebrew/homebrew-php/issues/4527
SBIN="${SBIN:-"/usr/local/sbin"}"
log_verbose "creating $SBIN if needed"
if [[ ! -e $SBIN ]]; then
	# only use sudo if necessary
	$(config_sudo "$SBIN") mkdir -p "$SBIN"
fi
log_verbose "adding $SBIN to the profile if needed"
if ! config_mark; then
	# this no longer seems to work in Bash 5.0
	config_add <<<"export PATH+=:/usr/local/sbin"
fi

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
/usr/local/Cellar
/usr/local/Homebrew
/usr/local/Frameworks
/usr/local/share
/usr/local/lib
/usr/local/etc
/usr/local/sbin
"}"
for HOMEBREW in $HOMEBREW_DIRS; do
	log_verbose "checking $HOMEBREW"
	if [[ ! -e $HOMEBREW ]]; then
		log_verbose "$HOMEBREW does not exist skipping"
		mkdir -p "$HOMEBREW"
	fi
	# https://apple.stackexchange.com/questions/130685/understanding-the-staff-user-group
	members="$(dscacheutil -q group -a name "$(util_group "$HOMEBREW")" | grep ^users: | awk '{$1= ""; print $0}')"
	log_verbose "$members can access $HOMEBREW"
	if [[ $members =~ $USER ]]; then
		sudo chmod -R g+w "$HOMEBREW"
		log_verbose "cannot write to $HOMEBREW as user but made group writeable"
	fi
	log_verbose "need to change these to your $HOMEBREW_USER"
	sudo find "$HOMEBREW" \! -user "$HOMEBREW_USER" -a \! -type l -exec chown "$HOMEBREW_USER" {} \;
done

# https://apple.stackexchange.com/questions/175069/how-to-accept-xcode-license
xcode_license_accept

if ! command -v brew >/dev/null; then
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

log_assert "command -v brew > /dev/null" "brew installed"
