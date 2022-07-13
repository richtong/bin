#!/usr/bin/env bash
##
## installs keys and the right keychain (deprecated)
## Ubuntu 22.04 native gnome key ring now supports id_25519
## This replaces the gnome key ring with keychain 
## but now instead of doing this you just need to do an ssh-add
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
OPTIND=1
# delay evauation of $HOME until bash time
SSH_DIR="${SSH_DIR:-"\$HOME/.ssh"}"
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
source_lib lib-keychain.sh lib-install.sh lib-util.sh lib-config.sh lib-version-compare.sh
set -u
shift $((OPTIND - 1))

if ! in_os linux; then
	log_verbose "linux only"
fi

log_verbose "In linux $(in_linux) with version $(linux_version)"
if in_linux ubuntu && vergte "$(linux_version)" 22 ; then
    log_verbose "Latest Ubuntu 22.04 or later can use keyring"
    if ! config_mark "$HOME/.ssh/config"; then
        config_add "$HOME/.ssh/config" <<<"AddKeysToAgent yes"
    fi
    log_exit "Ubuntu set to automatically add persistent passphrase remembering"
fi

source_profile
package_install keychain

# needs to run on each subshell for windows terminal
if ! config_mark "$(config_profile_nonexportable)"; then
	log_verbose "Adding keychain adding to $(config_profile_nonexportable)"
	if (($# > 1)); then
		# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
		log_verbose "Adding specific keys $*"
		config_add "$(config_profile_nonexportable)" <<-EOF
			keychain "$@"
		EOF
	else
		log_verbose "look in $SSH_DIR for keys deferred to bashrc time"
		# https://stackoverflow.com/questions/23356779/how-can-i-store-the-find-command-results-as-an-array-in-bash/54561526#54561526
		# these may be symlinks so need -L
		config_add "$(config_profile_nonexportable)" <<-EOF
			mapfile -d "" KEYS < <(find -L "$SSH_DIR" -name "*.id_ed25519" -o -name "*.id_rsa")
			keychain "\${KEYS[@]}"
		EOF
	fi

	# delay the hostname determiniation until profile time
	config_add "$(config_profile_nonexportable)" <<-'EOF'
		source "$HOME/.keychain/$(uname -n)-sh"
	EOF

	log_verbose "sourcing profile"
	source_profile
fi

log_verbose "using keys ${KEYS[*]}"
log_verbose "ssh agent is $(env | grep SSH)"
# shellcheck disable=SC2086
if ! use_openssh_keychain "${KEYS[@]}"; then
	echo "reboot needed then rerun"
fi
