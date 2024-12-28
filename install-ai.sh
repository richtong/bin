#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install desktop AI tools like ChatGPT and Stability Diffusion
##
## https://www.digitaltrends.com/computing/how-to-run-stable-diffusion-on-your-mac/
#
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"

CIVITAI_CLI_CONFIG_DIR="${CIVITAI_CLI_CONFIG_DIR:-"$HOME/.config/civit-cli-manager"}"

SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:e:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs AI Tools including Stability Diffusion and ChatGPT, ComfyUI, CivitAI cli
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
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
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
# l
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

# https://lobehub.com/blog/5-ollama-web-ui-recommendation

PACKAGE+=(

	# fig - command completion and dotfile manager (bought by Amazon and closed)
	# gpt4all - lm-studio local runner (lm-studio now does this as well nicer us)
	# macgpt - ChatGPT in menubar (pretty useless, deprecated)
	# poe - a chatbot aggregator by Quora, allows multiple chats (not using)
	# shell-gpt - cli including running shell commands (never use deprecated)
	# vincelwt-chatgpt - ChatGPT in menubar (not using)
	# appflowy        # project manager based on ai (don't ever use)
	cursor          # pair programming using VScode, takes over the `code`
	diffusionbee    # diffusionbee - Stability diffusion on Mac
	lm-studio       # lm-studio -  run different LLMs from Hugging Face locally
	mochi-diffusion # mochi-diffusion - Stability diffusion on Mac (haven't used)
	parquet-cli     # command line opening parquet data files
	cursor          # ai code editor that's based on code
	zed             # yet another ai editor
	jan             # grafical front-end for llama.cpp

)
package_install "${PACKAGE[@]}"

MAS+=(
	6474268307 # Enchanted LLM Mac only selfhosted
)
mas_install "${MAS[@]}"

PYTHON_PACKAGE+=(

	civitai-models-manager # download image generation models
	open-interpreter       # let's LLMs run code locally

)
# No longer required I think
# "open-interpreter[local]"
# "open-interpreter[os]"

# Install Stabiliity Diffusion with DiffusionBee"
# Download Chat GPT in menubar
# Use brew install instead of
#ARCH=x86
#if mac_is_arm; then
#ARCH=arZZm64
#fi
#download_url_open "https://github.com/vincelwt/chatgpt-mac/releases/download/v0.0.5/ChatGPT-0.0.5-$ARCH.dmg"
pipx_install "${PYTHON_PACKAGE[@]}"

# https://comfyorg.notion.site/ComfyUI-Desktop-User-Guide-1146d73d365080a49058e8d629772f0a#1486d73d3650800089f3fca8e5c94203
log_verbose "Install Alpha version of ComfyUI Desktop"
download_url_open "https://download.comfy.org/mac/dmg/arm64"

log_verbose "find open-interpreter models at https://docs.litellm.ai/docs/providers/"
log_verbose "gemini-pro o1-mini claude-3-5-sonnetjj"

mkdir -p "$CIVITAI_CLI_CONFIG_DIR"
if ! config_mark "$CIVITAI_CLI_CONFIG_DIR/.env"; then
	log_verbose "installing CivitAI cli"
	config_add "$CIVITAI_CLI_CONFIG_DIR/.env" <<-EOF
		# CIVITAI_TOKEN do a 1Password item get in .bash_profile
		MODELS_DIR="$COMFYUI_USER_DIR/models"
		OLLAMA_API_BASE=http://localhost:11434
		# OLLAMA_API_BASE=http://host.docker.internal:11434
	EOF
fi

# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

log_verbose "install ollama, open-webui and models"
"$BIN_DIR/install-ollama.sh"
