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
	# huggingface-cli # hf.co download files use huggingface_hub instead
	ffmpeg      # needed by open-webui
	llama.cpp   # underlying server to ollama
	ngrok       # local ssh gateway for open-webui
	ollama      # ollama - ollama local runner
	parquet-cli # command line opening parquet data files
	tika        # Apache tika content extractor command line

)
package_install "${PACKAGE[@]}"
log_verbose "packages installed"

echo "util_os=$(util_os)"

if in_os mac; then
	log_verbose "Mac installs"

	CASK+=(
		# appflowy        # project manager based on ai (don't ever use)
		# fig - command completion and dotfile manager (bought by Amazon and closed)
		# gpt4all - lm-studio local runner (lm-studio now does this as well nicer us)
		# jan             # grafical front-end for llama.cpp (deprecate for ollama)
		# lm-studio       # lm-studio -  run different LLMs from Hugging Face locally (deprecated)
		# macgpt - ChatGPT in menubar (pretty useless, deprecated)
		# ollamac # ollamac is a mac app crashes on startup deprecated
		# poe - a chatbot aggregator by Quora, allows multiple chats (not using)
		# shell-gpt - cli including running shell commands (never use deprecated)
		# vincelwt-chatgpt - ChatGPT in menubar (not using)
		cursor          # pair programming using VScode, takes over the $(code)
		diffusionbee    # diffusionbee - Stability diffusion on Mac
		mochi-diffusion # mochi-diffusion - Stability diffusion on Mac (haven't used)
		zed             # yet another ai editor

	)
	brew_install "${CASK[@]}"

	MAS+=(
		6474268307 # Enchanted LLM Mac only selfhosted

	)
	mas_install "${MAS[@]}"

fi

PYTHON_PACKAGE+=(

	# civitai-models-manager # download image generation models use comfy instead
	open-interpreter # let's LLMs run code locally
	open-webui
	"huggingface_hub[cli]"
	mlx
	mlx_lm

)

# No longer required I think
# "open-interpreter[local]"
# "open-interpreter[os]"

declare -A PYTHON_PACKAGE_FLAG+=(
	["open-webui"]="-p 3.12" # include the required python version
)

for package in "${PYTHON_PACKAGE[@]}"; do
	# shellcheck disable=SC2086
	pipx_install ${PYTHON_PACKAGE_FLAG[$package]:-} "$package"
done

log_verbose "install current shell completion"
open-webui --install-completion

for package in "${!PYTHON_PACKAGE_VERSIONED[@]}"; do
	pipx_install -p "${PYTHON_PACKAGE_VERSIONED[$package]}" "$package"
done
if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then open-webui --install-completion >/dev/null; fi
	EOF
fi

log_verbose "For TNE.ai only install VITE keys so put in $WS_DIR"
# note that this allows each WS_DIR to have its own copy of open-webui
# information
if ! config_mark "$WS_DIR/git/src/.envrc"; then
	config_add "$WS_DIR/git/src/.envrc" <<-'EOF'
		[[ -v VITE_AWS_KEY ]] || export VITE_AWS_KEY="$AWS_ACCESS_KEY_ID"
		[[ -v VITE_AWS_SECRET ]] || export VITE_AWS_SECRET="$AWS_SECRET_ACCESS_KEY"
		[[ -v VITE_OPEN_API_KEY ]] || export VITE_OPEN_API_KEY="$OPENAI_API_KEY"
		[[ -v DATA_DIR ]] || export DATA_DIR="$WS_DIR/data/open-webui/data"
		[[ -v JUPYTERLAB_TOKEN ]] || export "JUPYTERLAB_TOKEN"="$(op item get "JupyterLab Local Token Dev" --fields "token" --reveal)"
	EOF
fi

# https://comfyorg.notion.site/ComfyUI-Desktop-User-Guide-1146d73d365080a49058e8d629772f0a#1486d73d3650800089f3fca8e5c94203
log_verbose "Install Alpha version of ComfyUI Desktop"
download_url_open "https://download.comfy.org/mac/dmg/arm64"

log_verbose "find open-interpreter models at https://docs.litellm.ai/docs/providers/"
log_verbose "gemini-pro o1-mini claude-3-5-sonnetjj"

# not needed use the comfyui installer
# mkdir -p "$CIVITAI_CLI_CONFIG_DIR"
# if ! config_mark "$CIVITAI_CLI_CONFIG_DIR/.env"; then
# 	log_verbose "installing CivitAI cli"
# 	config_add "$CIVITAI_CLI_CONFIG_DIR/.env" <<-EOF
# 		# CIVITAI_TOKEN do a 1Password item get in .bash_profile
# 		MODELS_DIR="$COMFYUI_USER_DIR/models"
# 		OLLAMA_API_BASE=http://localhost:11434
# 		# OLLAMA_API_BASE=http://host.docker.internal:11434
# 		CIVITAI_BASE_URL=https://civitai.com
# 	EOF
# fi

# not needed with the brew installation
# log_verbose "install Jar for open-webui"
# TIKA_VERSION="${TIKA_VERSION:-2.9.2}"
# TIKA_JAR_FILE="${TIKA_JAR_FILE:-tika-server-standard-$TIKA_VERSION.jar}"
# TIKA_JAR_URL+=(
# 	"https://dlcdn.apache.org/tika/$TIKA_VERSION/$TIKA_JAR_FILE"
# )
# TIKA_JAR_DIR="${TIKA_JAR_DIR:-$HOME/jar}"
# TIKA_JAR_PATH="${TIKA_JAR_PATH:-$TIKA_JAR_DIR/$TIKA_JAR_FILE}"
# # usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
# for url in "${TIKA_JAR_URL[@]}"; do
# 	download_url "$url" "$TIKA_JAR_PATH" "$TIKA_JAR_DIR"
# done

log_verbose "Installing ${PYTHON_PACKAGE[*]}"
for package in "${PYTHON_PACKAGE[@]}"; do
	log_verbose "pipx install $package"
	pipx_install "$package"
done
if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then open-webui --install-completion >/dev/null; fi
	EOF
fi

log_verbose "tne.ai Orion settings"
if ! config_mark "$WS_DIR/git/src/.envrc"; then
	config_add "$WS_DIR/git/src/.envrc" <<-'EOF'
		# for open-webui and comfyui integration and tne ui
		[[ -v COMFYUI_BASE_URL ]] || COMFYUI_BASE_URL="https://localhost:8188"
		[[ -v GOOGLE_DRIVE_API_KEY ]] || export "GOOGLE_DRIVE_API_KEY"="$(op item get "Google Drive and Picker API Key Dev" --fields "api key" --reveal)"
		[[ -v GOOGLE_DRIVE_CLIENT_ID ]] || export "GOOGLE_DRIVE_CLIENT_ID"="$(op item get "Google OAuth Client ID Dev" --fields "client id" --reveal)"
		# For tne.ai orion
		[[ -v VITE_AWS_KEY ]] || export VITE_AWS_KEY="$AWS_ACCESS_KEY_ID"
		[[ -v VITE_AWS_SECRET ]] || export VITE_AWS_SECRET="$AWS_SECRET_ACCESS_KEY"
		[[ -v VITE_OPEN_KEY ]] || export VITE_OPEN_KEY="$OPENAI_API_KEY"
		[[ -v DATA_DIR ]] || export DATA_DIR="$WS_DIR/data/open-webui/data"
		[[ -v MODEL_API_KEY ]] || export "MODEL_API_KEY"="$(op item get "Open WebUI Local API Key" --fields "api key" --reveal)"
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

log_verbose "install comfyUI and models"
"$BIN_DIR/install-comfyui.sh"

log_verbose "install Jupyter so open-webui can run code there"
"$BIN_DIR/install-jupyter.sh"

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
