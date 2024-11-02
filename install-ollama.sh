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
	jan     # yet another ollama front-end (but why?)

)

package_install "${PACKAGE[@]}"

MAS+=(

	6474268307 # Enchanted LLM Mac only selfhosted

)
mas_install "${MAS[@]}"

PYTHON_PACKAGE+=(

	open-webui # create a web app at localhost:8080 run with open-webui server

)

# Install Stabiliity Diffusion with DiffusionBee"
# Download Chat GPT in menubar
# Use brew install instead of
#ARCH=x86
#if mac_is_arm; then
#ARCH=arm64
#fi
#download_url_open "https://github.com/vincelwt/chatgpt-mac/releases/download/v0.0.5/ChatGPT-0.0.5-$ARCH.dmg"
# if [[ -v poetry_active ]]; then
# 	log_verbose "In poetry so add to the project"
# 	log_warning "If you want in the system, you must exit poetry and rerun"
# 	poetry add "${PYTHON_PACKAGE[@]}"
# else
log_verbose "Pip install only in current environment rerun in other venvs"
pipx_install "${PYTHON_PACKAGE[@]}"
# fi

# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc"

# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

if ! config_mark "$(config_profile_interactive)"; then
	config_add "$(config_profile_interactive)" <<-EOF
		if command -v open-webui > /dev/null; then open-webui --install-completion; fi
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
	# now sorted by date added from ollama
	aya-expanse:8b       # cohere model 128k content 23 languages
	aya-expanse:32b      # cohere model 128k content
	granite3-guardian:2b #  prompt guard ibm
	granite3-guardian:8b #  prompt guard ibm
	granite3-moe:1b      # mixture of experts low latency
	granite3-moe:3b
	granite3-dense:2b    # RAG, code  generation, translation
	granite3-dense:8b    # RAG, code  generation, translation
	nemotron:70b         # nviida tuned llama 3.1
	shieldgemma:2b       # safety of text prompts
	shieldgemma:9b       # safety of text prompts
	shieldgemma:27b      # safety of text prompts
	llama-guard3:1b      # safety of prompts
	llama-guard3:8b      # safety of prompts
	qwen2.5-coder:1.5b   # 128K Tuned for coding 7B
	qwen2.5-coder:7b     # 128K Tuned for coding 7B
	llama3.2:3b          # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:1b          # Meta 1B 128K context
	qwen2.5:7b           # 128K context Alibaba 2024-09-16 7b
	qwen2.5:14b          # 128K context Alibaba 2024-09-16 7b
	qwen2.5:32b          # 128K context Alibaba 2024-09-16 7b
	qwen2.5:72b          # 128K context Alibaba 2024-09-16 7b
	solar-pro:22b        # 22b comparable to llama 3.1 70b 4k context
	nemotron-mini:4b     # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	bespoke-minicheck:7b # Fact check 7B q4_K_M
	mistral-small:22b    # v0.3 Mistral 22b-instruct-2409-q4_0
	reader-lm:0.5b       # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:1.5b       # HTML to Markdown conversion 1.5B-q4_K_M
	yi-coder:9b          # 9B model q4 128K context
	minicpm-v:8b         # vision mLLM 8b-2.6-q4_0

	# these models are post llama3.1
	# llama3.1:8b-text-q4_0 # text tuned model poor

	starcoder2:7b         # 4GB
	starcoder2:15b        # 9GB
	deepseek-coder-v2:16b # 16-lite-base-q4_0 -- deepseek 2.5 replaces but no 16b yet
	phi3.5:3.8b           # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	codestral:22b         # 22B Mistral code model 32K context window
	# hermes3                   # fine tuned llama 3.1 8B 128K context
	# hermes3:70b               # fine tuned llama 3.1 q4 128K Context
	command-r:35b    # 128K context 35b 19GB
	bge-large:335m   # tokens to embeddings
	mistral-nemo:12b # 128k context 12b-instruct-2407-q4_0
	gemma2:9b        # Google 9B Q4 5.4GB 8K context
	gemma2:27b       # Q4 16GB 8K context
	mistral:7b       # 4GB 7B Q4
	mixtral:8x7b     # mistral moe
	moondream2:1.8b  # small vision LLM
	llava-llama3     # older vision model based on llama3

	hf.co/ICEPVP8977/Uncensored_gemma_2b                                 # make sure your hf enabled for shield tests
	hf.co/mradermacher/Llama-3.2-3B-Instruct-Spatial-SQL-1.0-GGUF:Q4_K_S # sql model
	hf.co/PurpleAILAB/SQL_Llama-3.2-3B-Instruct-uncensored_final-gguf    # living dangerously

	# purpose large models
	# llama3.1              # deprecated
	# mistral-large:123b-instruct-2407-q3_K_S # 128K context winod 123B-instruct-q3_K_S
	# command-r-plus:104b-q2_K # 39GB Q2 with 128K context for enterprise

)

log_verbose "Pulling ${MODEL[*]}"
for M in "${MODEL[@]}"; do
	log_verbose "Pulling model $M"
	ollama pull "$M"
done
