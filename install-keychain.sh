#!/usr/bin/env bash
##
## installs keys and the right keychain
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
SSH_DIR="${SSH_DIR:-"$HOME/.ssh"}"
while getopts "hdvk:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install correct keychain and list of keys
			flags: -d debug, -v verbose, -h help
				   directory with keys to be added (default: all keys in $SSH_DIR)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	k)
		SSH_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-keychain.sh lib-install.sh lib-util.sh lib-config.sh
set -u
shift $((OPTIND - 1))

if ! in_os linux; then
	log_verbose "linux only"
fi

package_install keychain

if (($# > 1)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	KEYS=("$@")
else
	log_verbose "look in $SSH_DIR for keys"
	# https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526#54561526
	# these may be symlinks so need -L
	mapfile -d "" KEYS < <(find -L "$SSH_DIR" -name "*.id_ed25519" -o -name "*.id_rsa")
	log_verbose "found ${KEYS[*]}"
fi

# needs to run on each subshell for windows terminal
if ! config_mark "$(config_shell_profile)"; then
	config_add "$(config-shell_profile)" <<-EOF
		keychain "${KEYS[@]}"
		source "$HOME/.keychain/$(uname -n)-sh"
	EOF
fi
source_profile

log_verbose "using keys ${KEYS[*]}"
log_verbose "ssh agent is $(env | grep SSH)"
# shellcheck disable=SC2086
if ! use_openssh_keychain "${KEYS[@]}"; then
	echo "reboot needed then rerun"
fi
