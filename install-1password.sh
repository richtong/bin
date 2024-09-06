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

OP_INIT="${OP_INIT:-false}"
# if Private you do not need to set
OP_VAULT="{OP_VAULT:-DevOps}"
# make this a null string normally
OP_KEYTYPE="{OP_KEYTYPE:- Dev}"
VERSION="${VERSION:-8}"
DIRENV="${DIRENV:-$HOME/.envrc}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvfr:e:oc:k:" opt; do
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

				   -r 1Password version number (default: $VERSION)

				   -c .envrc to use this vault (default: $OP_VAULT)
				   -e install into .envrc for direnv if DIRENV is set (default: $DIRENV)
				   -o $($OP_INIT && echo "No ")init for 1Password op plugins
				   -k 1Password Item Suffix (default: $OP_KEYTYPE)


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
		OP_INIT="$($OP_INIT && echo false || echo true)"
		export OP_INIT
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	r)
		VERSION="$OPTARG"
		;;
	e)
		DIRENV="$OPTARG"
		;;
	c)
		OP_VAULT="$OPTARG"
		;;
	k)
		OP_KEYTYPE="$OPTARG"
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

	if ! $FORCE && [[ -n $(find /Applications -maxdepth 1 -name "1Password*" -print -quit) ]]; then
		log_verbose "1Password for Mac already installed"
		exit
	fi

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
a
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
declare -A OP_ITEM
OP_ITEM=(
	[aws]="AWS Access Key"
	[cdk]="AWS Access Key"
	[doctl]="DigitalOcean Personal Access Token"
	[gh]="GitHub Personal Access Token"
	["huggingface-cli"]="Hugging Face API Token"
	[localstack]="LocalStack API Key"
	[openai]="OpenAI API Key"
	[oaieval]="OpenAI API Key"
	[oaievalset]="OpenAI API Key"
	[anthropic]="Anthropic API Key"
	[openrouter]="OpenRouter API Key"
	[groq]="Groq API Key"
	[replicate]="Replicate API Token"
	["google-gemini"]="Google Gemini API Key"
)

# the field where the token lives in the item
# add spaces around the "-"
# aws does not quite work because it needs two keys
# but normally we do not use this and use sso and
# apply special fixup later to add the ID
# note that Local stack is moving to auth tokens
# so auth token should be changed to when the plugin changes in 1password
declare -A OP_FIELD
OP_FIELD=(
	[aws]="access key id"
	[cdk]="secret access key"
	[doctl]=token
	[gh]=token
	["huggingface-cli"]="user access token"
	[localstack]="api key"
	[openai]="api key"
	[oaieval]="api key"
	[oaievalset]="api key"
	[anthropic]="api key"
	[openrouter]="key"
	[groq]="api key"
	[replicate]="api token"
	["google-gemini"]="api key"
)

declare -A DIRENV_ENV
DIRENV_ENV=(
	[aws]=AWS_ACCESS_KEY_ID
	[cdk]=AWS_SECRET_ACCESS_KEY
	[doctl]=DIGITALOCEAN_TOKEN
	[gh]=GITHUB_TOKEN
	["huggingface-cli"]=HF_TOKEN
	[localstack]=LOCALSTACK_API_KEY
	[openai]=OPENAI_API_KEY
	[oaieval]=OPENAI_API_KEY
	[oaievalset]=OPENAI_API_KEY
	[anthropic]=ANTHROPIC_API_KEY
	[openrouter]=OPENROUTER_API_KEY
	[groq]=GROQ_API_KEY
	[replicate]=REPLICATE_API_TOKEN
	["google-gemini"]=GOOGLE_GEMINI_API_KEY
)

# this creates a ./.op directory in the CWD so make sure we are at HOME

WORKING_DIR="$PWD"
PUSHED=false
if $FORCE || $OP_INIT; then
	if ! pushd "$HOME" >/dev/null; then
		log_warning "Could not go to HOME $HOME will create .op in $CWD"
		PUSHED=true
	fi
	for PLUG in "${PLUGIN[@]}"; do
		log_verbose "Installing $PLUG"
		op plugin init "$PLUG"
	done
fi

log_verbose "installing into $DIRENV note that this does slow direnv"
log_verbose "Only install into the main monorepo $SRC_DIR"
if [[ -n $DIRENV ]] && ! config_mark "$SRC_DIR/$DIRENV"; then
	for ENTRY in "${PLUGIN[@]}"; do
		log_verbose "Installing $ENTRY into $DIRENV"
		log_verbose "expert ${DIRENV_ENV[$ENTRY]} = "
		log_verbose "op item get ${OP_ITEM[$ENTRY]}"
		log_verbose "fields ${OP_FIELD[$ENTRY]}"
		config_add "$SRC_DIR/$DIRENV" <<-EOF
			export "${DIRENV_ENV[$ENTRY]}"="\$(op item get "${OP_ITEM[$PLUG]}${OP_KEYTYPE}" \\
				--fields "${OP_FIELD[$ENTRY]}" --vault "${OP_VAULT}" --reveal)"
		EOF
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
# 		EOF
# 	fi
# done

log_verbose "Add bash and zsh completions"
if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-EOF
		# shellcheck disable=SC1090
		source <(op completion bash)
		if [[ -e $HOME/.config/op/plugins.sh ]]; then . "$HOME/.config/op/plugins.sh"; fi
	EOF
fi

# assuming oh-my-zsh is installed
if ! config_mark "$(config_profile_nonexportable_zsh)"; then
	config_add "$(config_profile_nonexportable_zsh)" <<-EOF
		if [[ -e $HOME/.config/op/plugins.sh ]]; then . "$HOME/.config/op/plugins.sh"; fi
	EOF
	if ! grep -q "$(config_profile_nonexportable_zsh)" 1password; then
		config_add "$(config_profile_nonexportable_zsh)" <<-EOF
			plugins+=(1password)
		EOF
	fi
fi

# https://developer.1password.com/docs/cli/get-started/#step-2-turn-on-the-1password-desktop-app-integration
log_verbose "login to 1Password"
op signin
