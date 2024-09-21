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
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:e:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Ollama and models
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

#
# https://lobehub.com/blog/5-ollama-web-ui-recommendation

PACKAGE+=(

	# fig - command completion and dotfile manager (bought by Amazon and closed)
	# gpt4all - lm-studio local runner (lm-studio now does this as well nicer us)
	# macgpt - ChatGPT in menubar (pretty useless, deprecated)
	# poe - a chatbot aggregator by Quora, allows multiple chats (not using)
	# shell-gpt - cli including running shell commands (never use deprecated)
	# vincelwt-chatgpt - ChatGPT in menubar (not using)
	ollama  # ollama - ollama local runner
	ollamac # ollamac is a self contained mac app crashes on startup

)
package_install "${PACKAGE[@]}"

MAS+=(
	6474268307 # Enchanted LLM Mac only selfhosted

)
mas_install "${MAS[@]}"

PIP_PACKAGE+=(

	open-interpreter # local llm run with interpreter at the cli with interpreter
	open-webui       # create a web app at localhost:8080 run with open-webui server

)

# Install Stabiliity Diffusion with DiffusionBee"
# Download Chat GPT in menubar
# Use brew install instead of
#ARCH=x86
#if mac_is_arm; then
#ARCH=arm64
#fi
#download_url_open "https://github.com/vincelwt/chatgpt-mac/releases/download/v0.0.5/ChatGPT-0.0.5-$ARCH.dmg"
log_verbose "Pip install only in current environment rerun in other venvs"
pip_install --upgrade "${PIP_PACKAGE[@]}"
log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc"

# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then
			open-webui --install-completion
		fi
	EOF
fi

if (($(pfind ollama | wc -l) == 0)); then
	log_verbose "ollama serve starting"
	ollama serve &
fi

MODEL+=(

	llama3.1                   # 8B, 98B-instruct-q4_0
	llama3.1:8b-text-q4_0      # test tuneded
	llama3.1:70b-instruct-q4_0 # 70b instruct 4bit- quantized
	gemma2                     # Google
	qwen2.5                    # Alibaba 2024-09-16
	qwen2.5-coder              # code specific
	phi3.5                     # Microsoft 3.8B-instruct-q4_0
	nemotron-mini              # nViida ropepaly, TAG QSA and function calling
	starcoder2                 ## 3B and 7B
	bespoke-minicheck          # Fact check 7B
	reader-lm                  # HTML to Markdown conversion 0.5B and 1.5B
	deepseek-v2.5              # 2024-09-03 integrated chat and instruct
	yi-coder                   # Coding 9B-instruct-q4_0
	mistral-large              # 128K context winod 123B

)

log_verbose "Pulling ${MODEL[*]}"
for M in "${MODEL[@]}"; do
	log_verbose "Pulling model $M"
	ollama pull "$M"
done
