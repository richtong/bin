#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install 1Password
## @author Rich Tong
## @returns 0 on success
#
# https://news.ycombinator.com/item?id=9091691 for linux gui
# https://news.ycombinator.com/item?id=8441388 for cli
# https://www.npmjs.com/package/onepass-cli for npm package
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"

# do not use OP_ as this is reserved for 1Password CLI
OP_API_INIT="${OP_API_INIT:-false}"
# if Private you do not need to set
# the default is a tne.ai account do not change OP_ACCOUNT which is the general default
# but you should copy the keys into your private repo
# OP_API_ACCOUNT="${OP_API_ACCOUNT:-63OLTT7NNJDFLOMAMAIDXWXYQM}"
# OP_API_VAULT="${OP_API_VAULT:-DevOps}"
OP_API_VAULT="${OP_API_VAULT:-Private}"
VERSION="${VERSION:-8}"
DIRENV_PROFILE="${ENV_PROFILE:-false}"
DIRENV_PATH="${DIRENV_PATH:-$HOME/.envrc}"
SHELL_PROFILE="${SHELL_PROFILE:-true}"
SSH_CONFIG="${SSH_CONFIG:-"$HOME/.ssh/config"}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvfr:e:oc:ns" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
				   -f $($FORCE && echo "do not ")force install even is 1Password exists
				   -n $(DIRENV_PROFILE && echo "no ")install variables in direnv (not recommended slow)
				   -e install into .envrc for direnv if DIRENV is set (default: $DIRENV_PATH)
				   -s $(SHELL_PROFILE && echo "no ")install variables in shell (recommended)

				   -r 1Password version number (default: $VERSION)

				   -c .envrc to use this vault (default: $OP_API_VAULT)
				   -o $($OP_API_INIT && echo "No ")init for 1Password op plugins


			For plugins, you should set y our 1Password to use special names
			so that op plugin init can find them and tag them as 1Password Shell Plugins
			And it needs to have the right URL as well. Defaults to your private repo.

			If you do  not get the field names quite right, the CLI will let you search your
			vault and then will rename the field for you.

			AWS:
			plugins [aws, cdk]
			field: [access key id, secret access key]
			url: aws.com
			DigitalOcean:
				plugin: Doctl:
				field: token
				url: digitalocean.com
			GitHub:
				plugin: Gh
				field: token
				url: https://github.com/settings/tokens
			HuggingFace
				plugin: huggingface-cli
				field: user access token
				url: https://huggingface.co/settings/tokens
			Localstack
				plugin: localstack
				field: api key
			OpenAI:
				plugin: [openai]
				field: api key

			To move to different user accounts look into your account names which
			you should set with domain hames to be convenient:
				op signin --account [tongfamily.com | tne.ai]

			To see different vaults you need to signin, you cannot see allvaults
			at once.

			Environment variables https://developer.1password.com/docs/cli/secret-references/
			op://<vault>/<item>[/<section]<field>?attribute=<attributed value>

			item: If the name is not unique, then you will get in op read the GUIDs
			vault: op list vault

			op signin --account tongfamily.com
			op run - looks for op:// in environment or file with --env-file= and populates for subshell
			op read - read specific secrets in scripts
			op plugin - to talk with third party CLIs

			Usage:

			cat "TOKEN=op://Private/Login Token/token" > .env
			op signin --account tongfamily.com
			op run --env-file=.env ./test_server.py

			To use with plugins, if you load the plugin then it will automatically send the crendentials over

			To use with direnv or scripts:

			1. First create a Unique name in your vault like $(OpenAI API Key) this must be unique
			2. In .envrc if you are using direnv call op
			export OPENAI_KEY="$(op item get 'OpenAI API Key' --field 'api key' --reveal)"
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
	o)
		OP_API_INIT="$($OP_API_INIT && echo false || echo true)"
		export OP_API_INIT
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	r)
		VERSION="$OPTARG"
		;;
	e)
		DIRENV_PATH="$OPTARG"
		;;
	c)
		OP_API_VAULT="$OPTARG"
		;;
	n)
		DIRENV_PROFILE="$($DIRENV_PROFILE && echo false || echo true)"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# just source if we are running in a mountable drive
if [[ $SCRIPT_DIR =~ /Volumes ]]; then
	# shellcheck disable=SC1091
	source lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh
else
	source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh
fi

if in_os linux && linux_version ubuntu; then

	if SANDBOX; then
		log_verbose "Install Linux graphical 1Password without cli or ssh-agent"
		flatpak_install 1password
		log_verbose "Also install the browser extensions manually"
	else
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
		echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list
		sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
		curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
		sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
		curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
		sudo apt update && sudo apt install 1password
	fi

elif in_os mac; then

	# if ! $FORCE && [[ -n $(find /Applications -maxdepth 1 -name "1Password*" -print -quit) ]]; then
	# 	log_verbose "1Password for Mac already installed"
	# 	exit
	# fi

	log_verbose using brew to install on Mac 1Password and the CLI
	if ! package_install 1password; then
		log_verbose "brew install failed trying to download the package"
		# download_url_open "https://d13itkw33a7sus.cloudfront.net/dist/1P/mac4/1Password-6.0.2.zip"
		# more general location
		# usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
		# Have to increment the OPM number as versions increase
		log_verbose "installed 1Password Version $VERSION"
		download_url_open "https://app-updates.agilebits.com/download/OPM$VERSION" "1Password.pkg"
	fi
	log_verbose "Install 1password for safari"
	mas_install 1569813296

fi

PACKAGE+=(
	1password-cli
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

log_verbose "Enable command line integrations to store credentials in 1Password"
# https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration
log_warning "In 1Password App go to Settings > Developers"
log_warning "And enable Use the SSH Agents, Integrate with 1Password CLI"
log_warning "and Check for devleoper credentials on disk"
log_warning "Enable Settings > Browser > Get 1Password for your Browser"
if in_os mac; then
	open -a "1Password.app"
fi

# https://developer.1password.com/docs/cli/shell-plugins/github/
# -brew - only need brew if you are hitting the github api rate limit when
# searching brew
# cdk - aws cloud development kit
# doctl - DigitalOcean CLI
# localstack - aws local development has a low cost cloud
# oaieval - OpenAI not needed and will cause duplicated .envrc
# oaievalset - OpenAI
log_warning "aws anc cdk should not use access key's, instead, use aws sso login"
PLUGIN+=(
	# aws
	# cdk
	doctl
	gh
	huggingface-cli
	localstack
	openai
	oaieval
	oaievalset
)

# 1Password API keys, tokens without secrets but which should go into DIRENV
ENTRY+=(
	openrouter
	replicate
	groq
	anthropic
)

# the list of 1Password names for each of these API keys
# need quotes for huggingface-cli because shfmt will
# do not use github_token, use gh auth login
# do not use AWS_SECRET_ACCESS_KEY, use AWS_SECRET_ACCESS_KEY use aws ssologin
declare -A OP_API_ITEM
OP_API_ITEM=(
	# [GITHUB_TOKEN]="GitHub Personal Access Token"
	# [LOCALSTACK_API_KEY]="LocalStack API Key"
	# [SUPERSET_SECRET_KEY]="Apache Superset Secret Dev"
	[ANTHROPIC_API_KEY]="Anthropic API Key Dev"
	[AWS_ACCESS_KEY_ID]="AWS Access Key"
	[AWS_SECRET_ACCESS_KEY]="AWS Access Key"
	[CIVITAI_TOKEN]="Civitai API Key Dev"
	[DEEPSEEK_API_KEY]="deepseek API Key Dev"
	[DIGITALOCEAN_ACCESS_TOKEN]="DigitalOcean Personal Access Token"
	[GOOGLE_API_KEY]="Google Gemini API Key Dev"
	[GITHUB_TOKEN_CLASSIC]="GitHub Personal Access Token Classic"
	[GOOGLE_AI_API_KEY]="Google Gemini API Key Dev" # used by zed
	[GROQ_API_KEY]="Groq API Key Dev"
	[HF_TOKEN]="Hugging Face API Token Dev"
	[MISTRAL_API_KEY]="Mistral API Key Dev"
	[OPENAI_API_KEY]="OpenAI API Key Dev"
	[OPENROUTER_API_KEY]="OpenRouter Key Dev"
	[REPLICATE_API_KEY]="Replicate API Token Dev"
	[SLASHGPT_ENV_WEBPILOT_UID]="Webpilot UID Dev"
	[WEBUI_SECRET_KEY]="Open WebUI Secret Key Dev"

)

# the field where the token lives in the item
# add spaces around the "-"
# aws does not quite work because it needs two keys
# but normally we do not use this and use sso and
# apply special fixup later to add the ID
# note that Local stack is moving to auth tokens
# so auth token should be changed to when the plugin changes in 1password
declare -A OP_API_FIELD
OP_API_FIELD=(
	# [GITHUB_TOKEN]=token
	# [LOCALSTACK_API_KEY]="api key"
	# [SUPERSET_SECRET_KEY]="api key"
	[ANTHROPIC_API_KEY]="api key"
	[AWS_ACCESS_KEY_ID]="access key id"
	[AWS_SECRET_ACCESS_KEY]="secret access key"
	[CIVITAI_TOKEN]="api key"
	[DEEPSEEK_API_KEY]="api key"
	[DIGITALOCEAN_ACCESS_TOKEN]=token
	[GOOGLE_API_KEY]="api key"
	[GITHUB_TOKEN_CLASSIC]="personal access token"
	[GOOGLE_AI_API_KEY]="api key"
	[GROQ_API_KEY]="api key"
	[HF_TOKEN]="user access token"
	[MISTRAL_API_KEY]="api key"
	[OPENAI_API_KEY]="api key"
	[OPENROUTER_API_KEY]="key"
	[REPLICATE_API_KEY]="api token"
	[SLASHGPT_ENV_WEBPILOT_UID]=key
	[WEBUI_SECRET_KEY]="secret key"

)
log_verbose "OP_API_FIELD:${OP_API_FIELD[*]}"
log_verbose "OP_API_FIELD[AN]:${OP_API_FIELD[ANTHROPIC_API_KEY]}"
# this creates a ./.op directory in the CWD so make sure we are at HOME

WORKING_DIR="$PWD"
PUSHED=false
if $FORCE || $OP_API_INIT; then
	if ! pushd "$HOME" >/dev/null; then
		log_warning "Could not go to HOME $HOME will create .op in $CWD"
		PUSHED=true
	fi
	for PLUG in "${PLUGIN[@]}"; do
		log_verbose "Installing $PLUG"
		op plugin init "$PLUG"
	done
fi

if $PUSHED && ! popd >/dev/null; then
	log_warning "Could not return to execution directory $WORKING_DIR"
fi

# signin is now sticky by default and my.1password.com has multiple
# accounts and no way to pick so disable this
# log_verbose "Installing auto login"
# for PROFILE in "" "$(config_profile_zsh)"; do
# 	if ! config_mark "$PROFILE"; then
# 		config_add "$PROFILE" <<-EOF
# 			# shellcheck disable=SC2086
# 			if command -v op >/dev/null && [ -n "${OP_SESSION+n}" ]; then
# 			eval "$(op signin)"; fi
# 	EOF
# 	fi
# done

# usage: 1password_export [profile file]
1password_export() {
	local profile_file="${1:-$config_profile}"
	log_verbose "1password export to file $profile_file"
	log_verbose "indices: ${!OP_API_ITEM[*]}"
	log_verbose "values: ${OP_API_ITEM[*]}"
	for op_api_index in "${!OP_API_ITEM[@]}"; do
		log_verbose "index $op_api_index"
		log_verbose "item ${OP_API_ITEM[$op_api_index]}"
		log_verbose "field ${OP_API_FIELD[$op_api_index]}"
		# https://stackoverflow.com/questions/3601515/how-to-check-if-a-variable-is-set-in-bash
		# do not overwrite if a key already exists
		# we are using bash syntax here since you can't put interactive stuff in
		# .profile
		# if you are going to use a shared vault then add this
		#			--account "$OP_API_ACCOUNT"
		config_add "$profile_file" <<-EOF
			[[ -v $op_api_index ]] || \\
				export "$op_api_index"="\$(op item get "${OP_API_ITEM[$op_api_index]}" \\
					--fields "${OP_API_FIELD[$op_api_index]}" --vault "$OP_API_VAULT" \\
					--reveal)"
		EOF
	done
}

if $DIRENV_PROFILE; then
	log_verbose "Install these in the universal export for the user"
	log_verbose "Installing in direnv is slow"
	touch "$DIRENV_PATH"
	if ! config_mark "$DIRENV_PATH"; then
		1password_export "$DIRENV_PATH"
	fi
fi

# shell too for each)
# since the 1password op needs user input we cannot put in the .profile
log_verbose "Add bash and zsh completions"
if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-EOF
		# shellcheck disable=SC1090
		source <(op completion bash)
		if [[ -e \$HOME/.config/op/plugins.sh ]]; then . "\$HOME/.config/op/plugins.sh"; fi
	EOF
	if $SHELL_PROFILE; then
		config_add "$(config_profile_nonexportable)" <<-EOF
			# only run if interactive as op calls 1password for authentication
			if [[ \$- == *i* ]]; then
		EOF
		log_verbose "adding 1password_export"
		1password_export "$(config_profile_nonexportable)"
		config_add "$(config_profile_nonexportable)" <<-EOF
			fi
		EOF
	fi

fi

# assuming oh-my-zsh is installed
if ! config_mark "$(config_profile_nonexportable_zsh)"; then
	config_add "$(config_profile_nonexportable_zsh)" <<-EOF
		if [[ -e \$HOME/.config/op/plugins.sh ]]; then . "\$HOME/.config/op/plugins.sh"; fi
	EOF
	config_add "$(config_profile_nonexportable_zsh)" <<-EOF
		plugins+=(1password)
	EOF

	if $SHELL_PROFILE; then
		config_add "$(config_profile_nonexportable_zsh)" <<-EOF
			# only run if interactive as op calls 1password for authentication
			if [[ -o login ]]; then
		EOF
		log_verbose "adding 1password_export"
		1password_export "$(config_profile_nonexportable_zsh)"
		config_add "$(config_profile_nonexportable_zsh)" <<-EOF
			fi
		EOF
	fi

fi

# https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration
log_verbose "login to 1Password"
op signin

log_verbose "Add .ssh/config settings for 1Password"
# need the forward agent so the 1Password goes there
if ! config_mark "$SSH_CONFIG"; then
	config_add "$SSH_CONFIG" <<-EOF
		Host *
			IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
			XAuthLocation /opt/X11/bin/xauth
			ForwardX11Timeout 596h
			# https://docs.github.com/en/authentication/connecting-to-github-with-ssh/using-ssh-agent-forwarding
			ForwardAgent Yes
	EOF
fi

# https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key
log_verbose "use ssh key for signing commits"
git config --global gpg.format ssh
# disable because op returns a double quoted string
# shellcheck disable=SC2046
log_verbose "add signing key"
# FIX this only adds the first id_ed25519
git config --global user.signingkey "$(op item get "GitHub SSH Key" --fields "public key" --reveal)"
# log_verbose "add 1password as app"
git config --global 'gpg "ssh".program' "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
# a bug so do not enable
log_verbose "enable signing"
git config --global commit.gpgsign true
