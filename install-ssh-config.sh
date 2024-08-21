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
USE_KEYCHAIN="${USE_KEYCHAIN:-false}"

OPTIND=1

while getopts "hdvk" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			            Installs ssh keys and AWS credentials into .ssh
			            Note this is deprecated you should use 1Password ssh key storage
			            and AWS SSO to pull keys instead.

						usage: $SCRIPTNAME [flags]
						flags: -h help
							   -d $(! $DEBUGGING || echo "no ")debugging
							   -v $(! $VERBOSE || echo "not ")verbose
							   -k do $(! $USE_KEYCHAIN || echo "not ")use keychain, use key-ring

		EOF
		exit
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
		if $VERBOSE; then export SSH_LOAD_FLAGS+=" -v "; fi
		;;
	k)
		# invert the variable when flag is set
		USE_KEYCHAIN="$($USE_KEYCHAIN && echo false || echo true)"
		export USE_KEYCHAIN
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-util.sh lib-keychain.sh lib-version-compare.sh lib-config.sh
log_verbose "Loaded shell libraries"
shift $((OPTIND - 1))

if in_os mac; then
	log_verbose "Installing for MacOS"

	# https://github.com/jirsbek/SSH-keys-in-macOS-Sierra-keychain
	# Note we could also create a LaunchAgent, but using bashrc
	# instead
	# https://apple.stackexchange.com/questions/48502/how-can-i-permanently-add-my-ssh-private-key-to-keychain-so-it-is-automatically
	log_verbose "for MacOS Sierra and above need this to reload keys previously was automatic"
	log_verbose "Create the keys with ssh-add -K and it will go into the keychain"
	log_verbose "make sure ~/.ssh/config has UseKeychain and AddKeysToAgent set to Yes"
	log_verbose "then you no longer need to manually add keys or have ssh-add -A in mac"
	log_verbose "but you do need this if you use ssh key forwarding so downstream"
	log_verbose "machines see all the keys you have profile"
	log_verbose "Mac configs"

	if vergte "$OSTYPE" darwin16; then
		log_warning "Make sure that in MacOS Sierra and above we have right ssh config options"
		log_warning "In older versions this was the default so no need to add these lines"
		SSH_LOAD_FLAG="--apple-load-keychain"
		SSH_USE_FLAG="--apple-use-keychain"

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

		log_warning "MacOS Sierra can stop here if you never need SSH Key forwarding but we use it so continue"
	else
		log_verbose "Older than MacOS Sierra just set old ssh flags -K and -A"
		SSH_LOAD_FLAG="-A"
		SSH_USE_FLAG="-K"
	fi

	# -A is now --apple-load-keychain for loading everything that is currently
	# in the keychain
	# and -K is --apple-use-keychain for adding something into
	log_verbose "Run ssh-add -K or --apple-load-keychain just once to load the passphrase into the keychain"
	if ! config_mark; then
		log_verbose "Add to $(config_profile) loading the keychain"
		# note this should be /bin/sh scripting
		# https://keith.github.io/xcode-man-pages/ssh-add.1.html
		# for MacOS earlier than Sierra, need ssh-add -A to load all passphrases from MacOS keychain"
		config_add <<-EOF
			            # shellcheck disable=1091
						if [ -z "\$SSH_AUTH_SOCK" ]; then . "$WS_DIR/git/src/bin/set-ssh-agent.sh"; fi
						# ssh-add is slow so only run if no keys in the agent
						if [ "\$(ssh-add -l | wc -l)" -le 1 ] ; then ssh-add $SSH_LOAD_FLAG; fi
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
	if in_os mac; then
		log_verbose "before checking keys add all from the Mac Keychain"
		ssh-add "$SSH_LOAD_FLAG"
	fi
	# https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
	log_verbose "checking for secrets in ssh-add -l"
	for secret in "${SECRET[@]}"; do
		log_verbose "looking for $secret"
		if ! ssh-add -l | cut -d ' ' -f 3 | grep -q "^$secret$"; then
			log_verbose "could not find $secret so adding to keychain"
			log_verbose "adding to the MacOS keychain and will be unlocked by user login"
			log_verbose "access all keys by ssh-add --apple-use-keychain in .profile"
			ssh-add "$SSH_USE_FLAG" "$secret"
		fi
	done

elif in_os linux && ! $USE_KEYCHAIN; then

	log_verbose "In Linux, using Gnome key-ring by default finds all keys in $HOME/.ssh"
	if $VERBOSE; then
		# https://wiki.gnome.org/Projects/GnomeKeyring/Ssh
		# ignore the error if none are set
		ssh-add -l || true
	fi

	log_verbose "Make sure AddKeysToAgent so gnome will handle passphrases"
	if [[ ! -L $HOME/.ssh/config ]]; then
		log_verbose ".ssh/config is a real file so make sure AddKeystoAgent is set"
		config_replace "$HOME/.ssh/config" "AddKeysToAgent" "AddKeysToAgent yes"
	fi

elif
	in_os linux && $USE_KEYCHAIN
then

	# this is legacy code before Gnome Keyring worked with id_ed25519
	log_verbose "make sure you run keychain to find the openssh keychain"
	package_install keychain
	if in_linux ubuntu; then
		log_verbose "add .ssh keys to the keychain"
		use_openssh_keychain
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
	fi
	source_profile
fi
