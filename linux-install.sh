#!/usr/bin/env bash
## vim: se noet ai sw=4 :
##
#
## install grub and moves to passwordless sudo
#
# need to use trap and not -e so bashdb works
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
PASSWORDLESS_SUDO="${PASSWORDLESS_SUDO:-false}"

OPTIND=1
FORCE=${FORCE:-false}
# which user is the source of secrets

while getopts "hdvfs" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Setup your Linux machine for bootup and debugging. This makes sure that on boot
			we turn off "quiet" so that you can see the boot messages and it enables the
			root password so that if you do a recovery mode you can log in as root. This is
			a security issue so make sure it is a robust password.

			usage: $SCRIPTNAME [flags..]

			flags: -v verbose
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
				   -s $(! $PASSWORDLESS_SUDO || echo "no ")sudo password
			       -f force a new password for root

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
	s)
		PASSWORDLESS_SUDO="$($PASSWORDLESS_SUDO && echo false || echo true)"
		;;
	f)
		FORCE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1091,SC1090
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh lib-install.sh
shift $((OPTIND - 1))

if ! in_os linux; then
	log_exit "Real linux only"
fi

if ! config_mark; then
	config_add <<-'EOF'
		if uname | grep -q Linux; then
			echo $PATH | grep "$HOME/Applications" || PATH="$HOME/Applications/:$PATH"
		fi
	EOF
fi

log_verbose "install sudo and lua"
# lua used by lib-config
package_install sudo lua5.2 ppa-purge
# no longer need keychain as of July 2022 Ubuntu has ed_25519 support
# "$SCRIPT_DIR/install-keychain.sh"
log_verbose Adding sudoers entry ignored if running under iam-key
SUDOERS_FILE="/etc/sudoers.d/10-$USER"
if $PASSWORDLESS_SUDO; then
	log_verbose "Not recommended enable passwordless sudo good for scripts only"
	log_verbose "For Ubuntu 20.04 and later sudoers.d not enabled"
	package_install sudo
	if ! groups | grep sudo; then
		log_warning "$USER not in sudo group add them"
	else
		if [[ ! -e $SUDOERS_FILE ]]; then
			sudo tee "$SUDOERS_FILE" <<<"$USER ALL=(ALL:ALL) NOPASSWD:ALL"
			sudo chmod 440 "$SUDOERS_FILE"
			EOF
		fi
	fi
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
log_verbose "note that snap does not work on WSL2"
# not this should no longer exist now that we are on docker
run_if "$SOURCE_DIR/scripts/build/install-dev-packages.sh"
# The new location for boot strap file and the Mac section below should do
# it all
run_if "$SOURCE_DIR/scripts/build/bootstrap-dev"

if in_wsl; then
	log_exit "Not for WSL"
fi

log_verbose configure grub for next reboot with dev flags
"$SCRIPT_DIR/install-grub.sh"
log_verbose "check for sudo"

# https://askubuntu.com/questions/155278/how-do-i-set-the-root-password-so-i-can-use-su-instead-of-sudo
if [[ $(sudo passwd -S root | awk '{print $2}') == P ]] && ! $FORCE; then
	log_exit root password already set choose -f if you want to overwrite
fi

log_warning set the root password which is needed if the machine borks and you are running in debug mode
sudo passwd
