#!/usr/bin/env bash
##
## install rich's opiniated view of how secrets work
## Uses the new Veracrypt repositories not ecryptfs and CoreStorage
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

OPTIND=1
SECRET_USER="${SECRET_USER:-"$USER"}"
SECRETS_DIR="${SECRETS_DIR:-"$HOME/.secret"}"

while getopts "hdvr:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Install ssh key and other secrets from Dropbox holding Veracrypt folders
			usage: $SCRIPTNAME [flags] secrets_dir
			flags: -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
			       -r private ssh key location root directory (default: $SECRETS_ROOT_DIR)
			       -u which user is the source of secrets from Dropbox (default: $SECRET_USER)

			positional: the location of the encrypted secret directory (default: $SECRETS_DIR)

		EOF
		exit
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		xport DEBUGGING
		xport DEBUGGING=true
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	r)
		SECRETS_ROOT_DIR="$OPTARG"
		;;
	u)
		SECRET_USER="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-util.sh lib-keychain.sh lib-version-compare.sh lib-config.sh lib-install.sh
shift $((OPTIND - 1))

if (($# > 0)); then
	SECRETS_DIR="$1"
fi
log_verbose "secrets in $SECRETS_DIR"

log_verbose make sure veracrypt and stow are loaded
package_install stow
"$SCRIPT_DIR/install-veracrypt.sh"

log_verbose "mounting veracrypt"
"$SCRIPT_DIR/veracrypt-mount.sh"
#log_verbose "Seed .ssh keys from $SECRETS_ROOT_DIR"
#"$SCRIPT_DIR/install-ssh-keys.sh" "$USER" "$(id -gn)" "$SECRETS_ROOT_DIR/ssh/$SECRET_USER" "$HOME/.ssh"
# instead of our home brew install-ssh-keys use stow
package_install stow

log_verbose "stowing from $SECRETS_DIR to $HOME/.ssh"
"$SCRIPT_DIR/secrets-stow.sh" -s "$SECRETS_DIR" "$HOME/.ssh" "$HOME/vpn"

log_verbose "Install .ssh/config defaults like Keychain"
"$SCRIPT_DIR/install-ssh-config.sh"
