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
if [[ -v poetry_active ]]; then
	log_verbose "In poetry so add to the project"
	log_warning "If you want in the system, you must exit poetry and rerun"
	poetry add "${PIP_PACKAGE[@]}"
else
	log_verbose "Pip install only in current environment rerun in other venvs"
	pip_install "${PIP_PACKAGE[@]}"
fi

# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc"

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

# note things like neovim code companion will use the first model
# that comes out of ollama list and this is the last one pulled, so this
# pull order has the default at the bottom
# These are too large for a 64GB machine
# deepseek-v2.5              # 2024-09-03 instruct 236B very large
MODEL+=(
	# vision
	minicpm-v    # vision mLLM 8b-2.6-q4_0
	llava-llama3 # older vision model based on llama3
	llava        # older vision model

	# big models
	mistral-large:123b-instruct-24-07-q3_K_S # 128K context winod 123B-instruct-q3_K_S
	command-r-plus                           # 104b-08-2024-q4_0 big at 59GB

	bespoke-minicheck     # Fact check 7B q4_K_M
	llama3.1:8b-text-q4_0 # test tuneded
	qwen2.5-math          # Alibaba math 7b-instruct-q4_K_M
	qwen2.5-math:72b      # Alibaba math 72b-instruct-q4_K_M

	# small LLMs
	phi3.5        # Microsoft 3.8B-instruct-q4_0
	nemotron-mini # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M

	# coder models
	reader-lm         # HTML to Markdown conversion 1.5B-q4_K_M
	deepseek-coder-v2 # 16-lite-base-q4_0
	qwen2.5-coder     # Alibaba coder 7b-bas-q4_K_M
	starcoder2        ## 7b chat or basenstruct-q4_0
	yi-coder          # 9B model q4

	# general purpose
	hermes3               # Nous research 8b
	hermes3:70b           # Nous research q4
	solarpro              # 22b comparable to llama 3.1 70b 4k context
	command-r             # 35b-08-2024-q4_0 at 18GB
	qwen2.5               # Alibaba 2024-09-16 7b-base-=q4_K_M
	qwen2.5:72b           # Alibaba 72b-instruct-q4_K-M instruct
	mistral-nemo          # 128k context 12b-instruct-2407-q4_0
	mistral-small         # Mistral 22b-instruct-2409-q4_0
	gemma2                # Google
	llama3.1:8b-text-q4_0 # text tuned model
	llama3.1:70b          # 70b instruct 70b-instruct-q4_0
	llama3.1              # 8B, 98B-instruct-q4_0

)

log_verbose "Pulling ${MODEL[*]}"
for M in "${MODEL[@]}"; do
	log_verbose "Pulling model $M"
	ollama pull "$M"
done
