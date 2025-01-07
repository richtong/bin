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
COMFYUI_USER_DIR="${COMFYUI_USER_DIR:-"$HOME/ComfyUI"}"

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
	cursor          # pair programming using VScode, takes over the $(code)
	diffusionbee    # diffusionbee - Stability diffusion on Mac
	lm-studio       # lm-studio -  run different LLMs from Hugging Face locally
	mochi-diffusion # mochi-diffusion - Stability diffusion on Mac (haven't used)
	parquet-cli     # command line opening parquet data files
	cursor          # ai code editor that's based on code
	zed             # yet another ai editor
	jan             # grafical front-end for llama.cpp
	tika            # Apache tika content extractor command line
	ngrok           # local ssh gateway for open-webui
	ffmpeg          # needed by open-webui
	llama.cpp       # underlying server to ollama

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

log_verbose "install Jar for open-webui"
TIKA_VERSION="${TIKA_VERSION:-2.9.2}"
JAR_URL+=(
	"https://dlcdn.apache.org/tika/$TIKA_VERSION/tika-server-standard-$TIKA_VERSION.jar"
)
JAR_PATH="${JAR_PATH:-$HOME/jar}"
# usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
for url in "${JAR_URL[@]}"; do
	download_url "$url"
done

for package in "${!PYTHON_PACKAGE[@]}"; do
	pipx_install -p "${PYTHON_PACKAGE[$package]}" "$package"
done
if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then open-webui --install-completion >/dev/null; fi
	EOF
fi
# note things like neovim code companion will use the first model
# that comes out of ollama list and this is the last one pulled, so this
# pull order has the default at the bottom
# These are too large for a 64GB machine
# note we load latest and also the tagged version

# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

log_verbose "install ollama models"
"$BIN_DIR/install-ollama.sh"

# https://dashboard.ngrok.com/get-started/setup/macos
log_verbose "configure ngrok as front-end to open-webui with make auth with the right ngrok 1Password item"

# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc
log_verbose "WEBUI_SECRET_KEY and OPENAI_API_KEY should both be defined before running ideally in a .envrc"
log_verbose "Or put the API key into OpenWebUI"
log_verbose "To add Groq to OPen-webui Lower Left > Admin Panel > Settings > Connections > OpenAI API"
log_verbose "Click on + on he right and add URL https://api.groq.com/openai/v1 and your GROQ key"
# https://zohaib.me/extending-openwebui-using-pipelines/
# log_verbose "https://github.com/open-webui/pipelines"
log_verbose "To add Gemini, add functions or pipelines you need to run a docker and add it"
log_verbose 'docker run -d -p 9099:9099 --add-host=host.docker.internal:host-gateway \ '
log_verbose '-v pipelines:/app/pipelines --name pipelines --restart always \ '
log_verbose "ghcr.io/open-webui/pipelines:main"
log_verbose "or fork and submodule add git@githbu.com:open-webui/pipelines"
log_verbose "pip install - requriements.txt && sh .start.sh"

log_verbose "Installing the pipelines interface which allows compatible interfaces"
log_verbose "See https://github.com/open-webui/pipelines"

log_verbose "you can start servers separate with make ai"
