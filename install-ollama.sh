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

INCLUDE_MEDIUM="${INCLUDE_MEDIUM:-false}"
INCLUDE_LARGE="${INCLUDE_LARGE:-false}"
INCLUDE_HF="${INCLUDE_HF:-true}"
AUTOMATIC_BY_MEMORY="${AUTOMATIC_BY_MEMORY:-true}"
# if set to false will remove/uninstall models
ACTION="${ACTION:-pull}"

OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:e:s:lfmu" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Ollama models and removes obsolete or large ones
			usage: $SCRIPTNAME [ flags ]
			flags:
				-h help
				-d $(! $DEBUGGING || echo "no ")debugging
				-v $(! $VERBOSE || echo "not ")verbose
				-m $(! $INCLUDE_MEDIUM || echo "not ")pull larger then 10B+ parameters (need 10GB+ RAM)
				-l $(! $INCLUDE_LARGE || echo "not ")pull larger then 32B+ parameters (need 40GB+ RAM)
				-f $(! $INCLUDE_HF || echo "not ")pull huggingface models
				-u $([[ $ACTION == pull ]] || echo "un")install models
				-s storage location for models $([[ -v OLLAMA_MODELS ]] && echo default: "$OLLAMA_MODELS")
				-a $(! AUTOMATIC_BY_MEMORY || echo "not ")automatic by system memory
					always install base and hugging face models
					system memory > 32GB add medium models
					system memory > 64GB add large models

			example of manual: Uninstall large and medium models and hugging face models
				$SCRIPTNAME -u -l -m -h
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;&
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	m)
		# invert the variable when flag is set
		INCLUDE_MEDIUM="$($INCLUDE_MEDIUM && echo false || echo true)"
		export INCLUDE_MEDIUM
		;;

	l)
		# invert the variable when flag is set
		INCLUDE_LARGE="$($INCLUDE_LARGE && echo false || echo true)"
		export INCLUDE_LARGE
		;;
	f)
		# invert the variable when flag is set
		INCLUDE_HF="$($INCLUDE_HF && echo false || echo true)"
		export INCLUDE_HF
		;;
	u)
		# invert action between pull and rm
		ACTION="$([[ $ACTION == pull ]] && echo rm || echo pull)"
		export ACTION
		;;
	s)
		OLLAMA_MODELS="$OPTARG"
		export OLLAMA_MODELS
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
		if command -v open-webui > /dev/null; then open-webui --install-completion >/dev/null; fi
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
# note we load latest and also the tagged version

# we put all the big models here if you are disk constrained
# now sorted by date added from ollama as of 11-15-24

# these are pre llama3.2 and subject to deprecation

MODEL_HF+=(
	hf.co/ICEPVP8977/Uncensored_gemma_2b                                 # make sure your hf enabled for shield tests
	hf.co/mradermacher/Llama-3.2-3B-Instruct-Spatial-SQL-1.0-GGUF:Q4_K_S # sql model
	hf.co/PurpleAILAB/SQL_Llama-3.2-3B-Instruct-uncensored_final-gguf    # living dangerously
)

# These are kept in most recent first from https://ollama.com/search?o=newest
# These models fit in 64GB and are less than 30B parameters
MODEL+=(
	marco-o1 # Alibab open large reasoning
	marco-o1:7b
	tulu3 # AI2 model
	tulu3:8b
	opencoder      # completely open source
	opencoder:1.5b #  english and chinse
	opencoder:8b   # reproducible
	smollm2        # open source
	smollm2:135m   # 135m is small
	smollm2:1.7b   # large is smarll
	granite3-guardian
	granite3-guardian:8b #  prompt guard ibm
	aya-expanse          # cohere
	aya-expanse:8b       # cohere model 128k content 23 languages
	granite3-moe         # mixture of experts
	granite3-moe:3b
	granite3-dense
	granite3-dense:2b # RAG, code  generation, translation
	granite3-dense:8b # RAG, code  generation, translation
	shieldgemma
	shieldgemma:2b # safety of text prompts
	shieldgemma:9b # safety of text prompts
	llama-guard3
	llama-guard3:1b    # safety of prompts
	llama-guard3:8b    # safety of prompts
	llama3.2           # Meta 3.2-3B Q4 128 context
	llama3.2:3b        # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:1b        # Meta 1B 128K context
	qwen2.5-coder      # Alibaba model
	qwen2.5-coder:1.5b # 128K Tuned for coding 7B
	qwen2.5-coder:7b   # 128K Tuned for coding 7B

	# these models are pre llama3.2 and subject to deprecation
	solar-pro:22b    # 22b comparable to llama 3.1 70b 4k context
	nemotron-mini:4b # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	qwen2.5
	qwen2.5:7b           # 128K context Alibaba 2024-09-16 7b
	qwen2.5:14b          # 128K context Alibaba 2024-09-16 7b
	qwen2.5:32b          # 128K context Alibaba 2024-09-16 7b
	bespoke-minicheck:7b # Fact check 7B q4_K_M
	mistral-small        # on the bubble to remove
	mistral-small:22b    # v0.3 Mistral 22b-instruct-2409-q4_0
	reader-lm
	reader-lm:0.5b # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:1.5b # HTML to Markdown conversion 1.5B-q4_K_M
	yi-coder:9b    # 9B model q4 128K context
	phi3.5:3.8b    # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?

	# these models are pre llama3.1 and are very close to gone
	bge-large:335m # tokens to embeddings

	gemma2:9b # Google 9B Q4 5.4GB 8K context

)
#
# these are models which are under 10B parameters
log_verbose "loading all models over 9B parameters, requires >16GB RAM"
MODEL_MEDIUM+=(
	qwq
	qwq:32b             # Alibaba advanced reasoning
	llama3.2-vision     # should run in open-webui
	llama3.2-vision:11b # vision works now
	aya-expanse:32b     # cohere model 128k content
	shieldgemma:27b     # safety of text prompts
	qwen2.5-coder:32b   # 128K Tuned for coding 7B
	gemma2:27b          # large gemma
)

log_verbose "loading all models over 32B parameters, requires >64GB RAM"
MODEL_LARGE+=(
	tulu3:70b           # AI2 instruction following
	athene-v2           # nexusflow based on qwen2.5
	athene-v2:72b       # code, math, log extraction
	llama3.2-vision:90b # vision works now
	nemotron            # nvidia llama 3.1 obsolete soon
	nemotron:70b        # nviida tuned llama 3.1
	qwen2.5:72b         # 128K context Alibaba 2024-09-16 7b
)
#
# move the deprecated models here to make sure to delete them
MODELS_REMOVE+=(
	# post llama3.2 but trying new vision models
	minicpm-v
	minicpm-v:8b  # vision mLLM 8b-2.6-q4_0
	deepseek-v2.5 # 236B is way too big for a 64GB machine
	hermes3       # fine tuned llama 3.1 8B 128K context
	hermes3:70b   # fine tuned llama 3.1 q4 128K Context
	smollm        # small language models on device
	smollm:135m   # 135m is small
	smollm:1.7b
	mistral-large
	mistral-large:123b-instruct-2407-q3_K_S # 128K context winod 123B-instruct-q3_K_S

	llama3.1              # deprecated
	llama3.1:8b-text-q4_0 # text tuned model poor results

	# models pre-llama3.1
	mistral-nemo
	mistral-nemo:12b # 128k context 12b-instruct-2407-q4_0
	firefunction-v2
	firefunction-v2:70b
	deepseek-coder-v2
	deepseek-coder-v2:16b # 16-lite-base-q4_0 -- deepseek 2.5 replaces but no 16b yet
	codestral:22b         # 22B Mistral code model 32K context window
	llava-llama3          # older vision model based on llama3
	moondream2            # small vision LLM
	moondream2:1.8b       # small vision LLM
	starcoder2
	starcoder2:7b            # 4GB
	starcoder2:15b           # 9GB
	mistral:7b               # 4GB 7B Q4 (deprecated)
	command-r-plus:104b-q2_K # 39GB Q2 with 128K context for enterprise
	command-r:35b            # 128K context 35b 19GB
	mixtral
	mixtral:8x7b # mistral moe (deprecated)

)

if $AUTOMATIC_BY_MEMORY; then
	log_verbose "Automatic model load by memory"
	# https://superuser.com/questions/197059/mac-os-x-sysctl-get-total-and-free-memory-size
	# 2**30 is 1GB
	MEMORY=$(($(sysctl -n hw.memsize) / 2 ** 30))
	log_verbose "Memory size is $MEMORY"
	# https://stackoverflow.com/questions/12614011/using-case-for-a-range-of-numbers-in-bash
	# https://stackoverflow.com/questions/12010686/case-statement-fallthrough
	# conditional arithmetic expressions return 1 if true and 0 if false
	# shellcheck disable=SC2194
	# the memory needs cascade down so start with the highest number first
	case 1 in
	$((MEMORY > 64)))
		INCLUDE_LARGE=true
		;&
	$((MEMORY > 32)))
		INCLUDE_MEDIUM=true
		;&
	esac
	log_verbose "automatic sets INCLUDE_MEDIUM=$INCLUDE_MEDIUM INCLUDE_LARGE=$INCLUDE_LARGE"
fi

MODEL_LIST=("${MODEL[@]}")
if $INCLUDE_LARGE; then
	MODEL_LIST+=("${MODEL_LARGE[@]}")
fi
if $INCLUDE_MEDIUM; then
	MODEL_LIST+=("${MODEL_MEDIUM[@]}")
fi
if $INCLUDE_HF; then
	MODEL_LIST+=("${MODEL_HF[@]}")
fi
log_verbose "Action $ACTION on ${MODEL_LIST[*]}"

# usage: ollama_action [ pull | rm  | ls] [ models...]
ollama_action() {
	local action="$1"
	shift

	for M in "$@"; do
		if [[ $action == rm ]] && ! ollama ls "$M" | cut -d ' ' -f 1 | grep -q "^$M$"; then
			continue
		fi
		log_verbose "$action model $M"
		ollama "$action" "$M"
	done
}

log_verbose "$ACTION on ${MODEL_LIST[*]}"
ollama_action "$ACTION" "${MODEL_LIST[@]}"

log_verbose "Removing deprecated models ${MODELS_REMOVE[*]}"
ollama_action rm "${MODELS_REMOVE[@]}"

if [[ -v OLLAMA_MODELS ]]; then
	log_verbose "Changing default storage of models to $OLLAMA_MODELS"
	if ! config_mark; then
		config_add <<-EOF
			if [ -z "\${OLLAMA_MODELS+x} ]; then OLLAMA_MODELS="$OLLAMA_MODELS"; fi
		EOF
	fi
fi
