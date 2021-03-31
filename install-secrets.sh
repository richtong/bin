#!/usr/bin/env bash
##
## install rich's opiniated view of how secrets work
## Uses the new Veracrypt repositories not ecryptfs and CoreStorage
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
SECRET_USER="${SECRET_USER:-"$USER"}"
SECRETS_DIR="${SECRETS_DIR:-"$HOME/.secret"}"

while getopts "hdvr:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Install ssh key and other secrets from Dropbox holding Veracrypt folders
			usage: $SCRIPTNAME [flags] secrets_dir
			flags: -d debug, -v verbose, -h help
			       -r private ssh key location root directory (default: $SECRETS_ROOT_DIR)
			       -u which user is the source of secrets from Dropbox (default: $SECRET_USER)

			positional: the location of the encrypted secret directory (default: $SECRETS_DIR)

		EOF
		exit
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
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

log_verbose on Ubuntu use openssh keychain instead of gnome keyring does not handle id_ed25519
log_verbose make sure you run keychain to find the openssh keychain
if in_linux ubuntu; then
	log_verbose Make sure we are using the correct keychain as gnome does not handle id_25519 keys
	use_openssh_keychain
fi

if in_os mac; then
	# https://github.com/jirsbek/SSH-keys-in-macOS-Sierra-keychain
	# Note we could also create a LaunchAgent, but using bashrc
	# instead
	# https://apple.stackexchange.com/questions/48502/how-can-i-permanently-add-my-ssh-private-key-to-keychain-so-it-is-automatically
	log_verbose for MacOS Sierra and above need this to reload keys previously was automatic
	log_verbose Create the keys with ssh-add -K and it will go into the keychain
	log_verbose make sure ~/.ssh/config has UseKeychain and AddKeysToAgent set to Yes
	log_verbose "then you no longer need to manually add keys or have ssh-add -A in mac"
	log_verbose "but you do need this if you use ssh key forwarding so downstream"
	log_verbose machines see all the keys you have

	log_verbose profile

	log_verbose Mac configs
	if vergte "$OSTYPE" darwin16; then
		log_warning "Make sure that in MacOS Sierra and above we have right ssh config options"
		if ! grep "^AddKeysToAgent" "$HOME/.ssh/config"; then
			log_warning no AddKeysToAgent in .ssh/config
		fi
		if ! grep "^UseKeychain" "$HOME/.ssh/config"; then
			log_warning no UseKeychain
		fi
		if [[ ! -L $HOME/.ssh/config ]]; then
			log_verbose .ssh/config is a real file so make sure they are there
			config_replace "$HOME/.ssh/config" "AddKeysToAgent" "AddKeysToAgent yes"
			config_replace "$HOME/.ssh/config" "UseKeychain" "UseKeychain yes"
		fi
		log_warning MacOS Sierra can stop here if you never need SSH Key forwarding but we use it so continue
	fi

	log_verbose for MacOS earlier than Sierra, need ssh-add -K and -A

	log_verbose "$(config_profile)" config
	if ! config_mark; then
		config_add <<-EOF
			if [[ -z \$SSH_AUTH_SOCK ]]; then source "$WS_DIR/git/src/bin/set-ssh-agent.sh"; fi
			# ssh-add is slow so only run if no keys in the agent
			if (( \$(ssh-add -l | wc -l) <= 1 )); then ssh-add -A; fi
		EOF
	fi

	log_verbose "look for all the keys in the $HOME/.ssh file and add to MacOS keychain"
	# https://superuser.com/questions/273187/how-to-place-the-output-of-find-in-to-an-array
	# https://github.com/koalaman/shellcheck/wiki/SC2207
	# works for multiple lines
	mapfile -t SECRET < <(find "$HOME/.ssh" -name "*.id_ed25519" -o -name "*.id_rsa")
	log_verbose "turned secrets in an array with ${#SECRET[*]} elements"
	log_warning "if you get this repeatedly you need to make sure the ssh comment"
	log_warning "is the same as name ${SECRET[*]} in MacOS and debian and not the file name in ubuntu"
	log_warning "to do with ssh-keygen -c -f _key_ -C _key_"

	# Just get the commands assume these are the name of the files
	if [[ $OSTYPE =~ darwin ]]; then
		log_verbose before checking keys add all from the Mac Keychain
		ssh-add -A
	fi
	# https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
	log_verbose "checking for secrets in ssh-add -l"
	for secret in "${SECRET[@]}"; do
		log_verbose "looking for $secret"
		if ! ssh-add -l | cut -d ' ' -f 3 | grep -q "^$secret$"; then
			log_verbose "could not find $secret so adding to keychain"
			log_verbose adding to the MacOS keychain and will be unlocked by user login
			log_verbose access all keys by ssh-add -A in .bash_profile
			ssh-add -K "$secret"
		fi
	done
	log_exit MacOS pre-Sierra finished adding all keys to the system keychain
fi

log_verbose Install keychain into Linux startup and on Linux everytime you logon
log_verbose for the first time into your user account you will need to reenter the passphrases
if ! config_mark; then
	log_verbose "adding keyring checking to $(config_profile)"
	# note we use "EOF" so there are no bash variable substitutions
	# Note -execdir is recommended but does not seem to work properly in profile
	config_add <<"EOF"
# Get all the passphrases into a single ssh-agent the last + means run keychain once
find "$HOME/.ssh" \( -name "*.id_rsa" -o -name "*.id_ed25519" \) -exec keychain {} +
# Look for the correct ssh-agent so you only need to enter once
[[ -e $HOME/.keychain/$HOSTNAME-sh ]] && source "$HOME/.keychain/$HOSTNAME-sh"
EOF
	source_profile
fi
