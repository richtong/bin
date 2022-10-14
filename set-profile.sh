#!/usr/bin/env bash
## vi: ts=4 sw=4 noet:
##
## Setting up the profiles correctly (deprecated now use config_setup and config_setup_end
## https://www.anintegratedworld.com/basics-of-osx-bashrc-v-profile-v-bash_profile/
##
## Because you can get the sourcing wrong whenever you add to PATh
## that the command has already been run so look for the string in PATH
## before you add to it.
##
## On ubuntu
## http://unix.stackexchange.com/questions/88106/why-doesnt-my-bash-profile-work
##  .profile runs once at boot time by sh when the graphical interface starts must be non-interactive
##   On Ubuntu it starts as /dev/tty1 and then you login as /dev/tty2
##   and its output is hidden and also read by just sh
##   so use for setting environment variables. It is also read by sh if you
##   invoke in interactively. It's syntax should be /bin/sh not bash.
##  .bash_profile runs when you ssh in (but not .profile) because it is a login shell
##   so it needs .profile settings typically but it can also be interactive.
##   Unlike the Mac, you do not need to source .profile when you get to bash
##   because it already has been sourced at graphical device manager start time.
##  .bashrc executes every time you do a Gnome Terminal/New Window because it is a non-login shell
##   so it is used for things like alias and functions which be exported from a
##   parent shell so be careful on Ubuntu about sourcing it in .bash_profile to
##   prevent duplication
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
## between this. Note that we have to source .profile below, because in the
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
##
## So on Linux,
## .profile. gets all the PATHS and things done in /bin/sh syntax.
## .bashrc. gets your aliases and functions in bash syntax. it can interactive
##          but check $- =~ i first since it might be a ssh -c one-liner
## .bash_profile. source .profile and then you get .bashrc as well and it
##		   should have nothing else all the real work should be done by profile
##		   as none of this is read by Ubuntu
##
## On Mac
## http://stackoverflow.com/questions/18773051/how-to-make-os-x-to-read-bash-profile-not-profile-file
## when it boots or when a new Terminal Windows is created because
## it thinks it is a login shell (vs ubuntu where gnome terminal
## is a non-login shell), or an ssh sessions
## started, looks for profiles in this order and *stops* when a file is found
## on the first one it finds
##   /etc/.profile
##   ~/.bash_profile - so put all the interacgtive stuff here. What would
##   normally go into Ubuntu .profile goes here in the Mac
##   ~/.bash_login - not commonly used
##   ~/.profile - read by sh only, so .bash_profile should source it
##   programs like the old MacPorts puts things into .profile assuming you are
##   using sh and not bash. Put things in .profile if you want to support sh
##   and bash
## Terminal is non-standard in that it assumes every new Window is a new login
## shell, so typically the bash_profile has to source .bashrc
##
## On Mac
## .bash_profile. Has nothing and sources .profile
## .profile: /bin/sh syntax, only exportables like PATH and completions
##           sources .bashrc if it is BASH
## .bashrc: aliases, functions and shopts, interactive only if $- =~ i
##
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
# note we defer ealuation of home until source time
PROFILE_DIR="${PROFILE_DIR:-"$HOME"}"
FORCE="${FORCE:-false}"
while getopts "hdvs:f" opt; do
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
	s)
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

# keychain no longer used as of July 2022 as core Ubuntu support id_ed25519
# (finally!)
#log_verbose install keychain as it is used by linux for profiles
#package_install keychain

# could each profile change to determine if source is needed
profiles=0

profile="$PROFILE_DIR/.bash_profile"
if ! config_mark "$profile"; then
	log_verbose "source .profile from $profile"
	config_add "$profile" <<-"EOF"
		# run profile if you find it for an inbound ssh session on ubuntu
		[[ -e $HOME/.profile ]] && . "$HOME/.profile"
	EOF
	# never use profiles++ because (( )) fails if the value is a zero
	# https://askubuntu.com/questions/385528/how-to-increment-a-variable-in-bash
	((++profiles))
fi

# change the .profile use only sources
profile="$PROFILE_DIR/.profile"
if ! config_mark "$profile"; then
	config_add "$profile" <<-EOF
		 if [ -z "$WS_DIR" ]; then WS_DIR="\$HOME/ws"; export WS_DIR; fi
		 echo "\$PATH" | grep -q \"$WS_DIR/bin\" || PATH=\":$WS_DIR/bin\:\$PATH"
		 echo "\$PATH" | grep -q \"$HOME/.local/bin\" || PATH=\":$HOME/.local/bin\:\$PATH"
	EOF
	((++profiles))
fi

log_warning "$profiles profiles have changed, make sure to source source_profile in scripts or reboot the system"

return "$profiles"
