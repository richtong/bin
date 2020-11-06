#!/usr/bin/env bash
##
## vi: ts=4 sw=4 et:
## Setting up the profiles correctly
## https://www.anintegratedworld.com/basics-of-osx-bashrc-v-profile-v-bash_profile/
## On ubuntu
##  .profile runs once at boot time when the graphical interface unity start must be non-interactive
##  .bash_profile runs when you ssh in (but not .profile) because it is a login shell
##  .bashrc executes every time you do a Terminal/New Window because it is a non-login shell
##  http://unix.stackexchange.com/questions/88106/why-doesnt-my-bash-profile-work
## On Mac
## http://stackoverflow.com/questions/18773051/how-to-make-os-x-to-read-bash-profile-not-profile-file
## when it boots or when a new Terminal Windows is created because
## it thinks it is a login shell (vs ubuntu where gnome terminal
## is a non-login shell), or an ssh sessions
## started, looks for profiles in this order and *stops* on
## on the first one it finds
##   /etc/.profile
##   ~/.bash_profile
##   ~/.bash_login
##   ~/.profile
## Note that ~/.bashrc is never sourced
##   .bashrc
##
## Install the profiles into the folder which defaults to $HOME  assumes SCRIPTNAME is set
## Also assumes that SOURCE_DIR is set
##
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
PROFILE_DIR="${PROFILE_DIR:-"$HOME"}"
FORCE="${FORCE:-false}"
while getopts "hdvp:f" opt; do
	case "$opt" in
	h)
		echo set the profile for logins
		echo "usage: $SCRIPTNAME [flags...] [keys...]"
		echo "flags: -d debug, -h help -v verbose"
		echo "       -p where you want to put the profiles (default: $PROFILE_DIR)"
		echo "       -f force add settings (default: $FORCE)"
		echo
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	p)
		PROFILE_DIR="$OPTARG"
		;;
	f)
		FORCE=true
		FLAGS+=" -f "
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh
shift $((OPTIND - 1))
if [[ $OSTYPE =~ darwin ]]; then
	## On Mac
	## http://stackoverflow.com/questions/18773051/how-to-make-os-x-to-read-bash-profile-not-profile-file
	## when it boots or when a new Terminal Windows is created, or an ssh sessions
	## started, looks for profiles in this order and *stops* on
	## on the first one it finds
	##   /etc/.profile ##   ~/.bash_profile ##   ~/.bash_login ##   ~/.profile
	# Note that ~/.bashrc is never sourced
	## Install the profiles into the folder $1 which defaults to $HOME  assumes SCRIPTNAME is set
	## Also assumes that SOURCE_DIR is set
	##
	# usage: set_mac_profile [ use_secret [ home_directory [ keys ]]]
	# note we do not currently need the key list on the mac
	profile="$PROFILE_DIR/.bash_profile"
	log_verbose "Mac profile setting of $profile"
	if ! config_mark "$profile" && ! $FORCE; then
		# need to echo so variable substitution occures
		# we allow variable substitution here
		# Use the backslash to escape
		config_add "$profile" <<-EOF
			[[ \$PATH =~ "$SOURCE_DIR/bin" ]] || PATH+=":$SOURCE_DIR/bin"

		EOF
	fi
	exit
fi

## Setting up the profiles correctly
## On ubuntu... there are four scenarios
##
## When you first login to a system without a graphical interface, this is
## called a console login. http://mywiki.wooledge.org/DotFiles
## and it looks for .bash_profile then .bash_login and finally .profile
## note that .profile is used by all shells, so should be non bash specific
## Also note that .bashrc is *not* read for console login, so many folks will
## source .bashrc, this causes problems though when you do a gnome bootup.
## Technically what is happening is that gnome-terminal starts and reads
## ~/.bashrc.
## https://askubuntu.com/questions/463462/sequence-of-scripts-sourced-upon-login
##
## When you login with ssh, then instead of getty as the invoker, it is sshd
## but otherwise, it goes through the same and ends up in .profile
##
## If you are in a graphical session (an X-Windows session), then the invoker is
## the session manager and then only .bashrc is invoked
##
## When Ubuntu first starts, this is called shell (eg Unity for Ubuntu, Gnome
## for Debian), then it will read ~/.profile, this means that you should not
## have interactive questions in ~/.profile

## So the way we use this is:
## .bashrc - Use this for new terminal windows, the main thing here is to use it
## to make sure that the ssh keys are correct since each temrinal session needs to
## bind to the same ssh-keyagent
## .bash_profile - Since this called before .profile, this is a good place to
## put commands that are just for ssh in, right now we have no diffeence
## betweeen this. Note that we have to source .profile below, because in the
## case that the machine is remote (an AWS machine for instance) we may never start
##    a graphical session (that is login to unity), so the way this kicks off is
##    to first call .bash_profile
##
## .profile - Since we only support bash shells, this is a convenient place
## to put things that should only run at system startup time. Really this can be
## at the start of the graphical desktop manager startup and must be non
## interactive. For instance this is a good place to put a check for zfs
## partitions which should only be run once on boot. You can put this elsewhere,
## but it is simpler. This is a place to put all the path changes to make sure
## the path is correct. This works because all gnome-terminals inherit from
## .profile. What technically happens is that .profile runs when you first login
## at a local machine from the graphical environment or when you ssh in

log_verbose installing linux profiles

log_verbose install keychain as it is used by linux for profiles
package_install keychain

profiles=0
log_verbose checking to .bash_profile used when you ssh into linux
profile="$PROFILE_DIR/.bash_profile"
if ! config_mark "$profile"; then
	log_verbose add to .bash profile which runs on ssh inbound session
	config_add "$profile" <<-"EOF"
		# run profile if you find it for an inbound ssh session on ubuntu
		[[ -e $HOME/.profile ]] && . "$HOME/.profile"
	EOF
	# never use profiles++ because (( )) fails if the value is a zero
	# https://askubuntu.com/questions/385528/how-to-increment-a-variable-in-bash
	((++profiles))
fi

log_verbose changing .profile runs once at boot time when the graphical desktop
log_verbose environment starts must be non-interactive
profile="$PROFILE_DIR/.profile"
if ! config_mark "$profile"; then
	config_add "$profile" <<<"[[ \$PATH =~ \"$SOURCE_DIR/bin\" ]] || PATH+=\":$SOURCE_DIR/bin\""
	((++profiles))
fi

log_verbose checking .bashrc which is run for every new terminal window start in
profile="$PROFILE_DIR/.bashrc"
log_verbose "currently we do not add to profile"
if ! config_mark "$profile"; then
	config_add "$profile" <<<"# No $profile entries from $SCRIPTNAME"
	((++profiles))
fi

log_warning profiles have changed, make sure to source source_profile in scripts or reboot the system
