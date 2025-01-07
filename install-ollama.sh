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
INCLUDE_EXTRA="${INCLUDE_EXTRA:-false}"

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
				-e $(! $INCLUDE_EXTRA || echo "not ")pull extra models if you have lots of disk (>2TB)
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
	e)
		# invert action between pull and rm
		INCLUDE_EXTRA="$($INCLUDE_EXTRA && echo false || echo true)"
		export INCLUDE_EXTRA
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
	ollama # ollama - ollama local runner
	# ollamac # ollamac is a mac app crashes on startup deprecated

)

package_install "${PACKAGE[@]}"

MAS+=(

	6474268307 # Enchanted LLM Mac only selfhosted

)
mas_install "${MAS[@]}"

declare -A PYTHON_PACKAGE+=(
	["open-webui"]=3.11 # include the required python version needs quotes to prevent reformat
)
# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc"
#
# Install Stabiliity Diffusion with DiffusionBee"
# Download Chat GPT in menubar
# Use brew install instead of
#ARCH=x86
#if mac_is_arm; then
#ARCH=arm64
#fi
#download_url_open "https://github.com/vincelwt/chatgpt-mac/releases/download/v0.0.5/ChatGPT-0.0.5-$ARCH.dmg"
# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

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
# https://github.com/ggerganov/llama.cpp/discussions/2094
# https://github.com/ggerganov/llama.cpp/pull/1684
# https://en.wikipedia.org/wiki/Perplexity
# Perplexity of 247 means for each word, you have 247 guesses
# Typically a q6 model is with 0.1% of the original fp16 model
# K quantization so Q4_K is type 1 auanitzation with 8 blocks using 4.5bpw
# q4 - 4 bit quantization of original floating point 16-bit model
# S, M or L - Small, Medium, Large which tellls you what Q you are
# using so Q4_K_M usts Q6_K for half the attention and feed forward
# To see the tradeoff for a 7B model, the perplexity (lower is better in bits
# per word and you can see why Q4_K_M is the default, at the knee of the curve
# 7B | F16 | Q2_K | Q3_K_M | Q4_K_M | Q5_K_M | Q6_K
# perplexity | 5.9066 | 6.4571 | 5.9061 | 5.9208 | 5.9110
MODEL+=(
	dolphin3                            # llama3.1 8B tuned
	dolphin3:latest                     # llama3.1 8B tuned
	dolphin3:8b                         # llama3.1 8B tuned
	dolphin3:8b-llama3.1-q4_K_M         # llama3.1 8B tuned
	smallthinker                        # Fine tuned Qwen2.5-b-instruct
	smallthinker:latest                 # qwq used to generate 8K synthetic
	smallthinker:3b                     # long sequence encourage CoT
	smallthinker:3b-preview-q8_0        # open dataset
	granite3.1-dense                    # IBM tool, RAG, code, translation
	granite3.1-dense:latest             # IBM
	granite3.1-dense:2b                 # RAG, code  generation, translation
	granite3.1-dense:2b-instruct-q4_K_M # RAG, code  generation, translation
	granite3.1-dense:8b                 # RAG, code  generation, translation
	granite3.1-dense:8b-instruct-q4_K_M # RAG, code  generation, translation
	granite3.1-moe                      # mixture of experts
	granite3.1-moe:latest               # low latency model
	granite3.1-moe:1b                   # low latency model
	granite3.1-moe:1b-instruct-q4_K_M   # low latency model
	granite3.1-moe:3b                   # larger model
	granite3.1-moe:3b-instruct-q4_K_M   # larger model
	falcon3
	falcon3:latest             # latest from Abu Dhabi
	falcon3:7b                 # 7B parameters
	falcon3:7b-instruct-q4_K_M # 7B parameters
	falcon3:3b                 # 7B parameters
	falcon3:3b-instruct-q4_K_M # 7B parameters
	falcon3:1b                 # 7B parameters
	falcon3:1b-instruct-q8_0
	granite-embedding # latest ibm embeddings
	granite-embedding:latest
	granite-embedding:30m
	granite-embedding:30m-en
	granite-embedding:278m
	granite-embedding:278m-fp16
	snowflake-arctic-embed2             # new embeddings
	snowflake-arctic-embed2:latest      # new embeddings
	snowflake-arctic-embed2:568m-l-fp16 # new embeddings
	snowflake-arctic-embed2:568m        # new embeddings
	marco-o1                            # Alibab open large reasoning
	marco-o1:latest                     # Alibab open large reasoning
	marco-o1:7b                         # 7b
	marco-o1:7b-q4_K_M                  # q4_K_M
	tulu3                               # AI2 instruction following
	tulu3:latest                        # full open source data, code, recipes
	tulu3:8b                            # 128 K content has 70B brother
	tulu3:8b-q4_K_M                     # standard quantization
	opencoder                           # completely open source
	opencoder:latest                    # completely open source
	opencoder:1.5b                      #  english and chinse
	opencoder:1.5b-instruct-q4_K_M      #  english and chinse
	opencoder:8b                        # reproducible
	opencoder:8b-instruct-q4_K_M        # reproducible
	smollm2                             # open source
	smollm2:latest                      # open source
	smollm2:135m-instruct-q4_K_M        # 135m is small
	smollm2:1.7b                        # large is smarll
	smollm2:1.7b-instruct-q4_K_M        # large is smarll
	granite3-guardian                   # IBM prompt risk
	granite3-guardian:latest            # IBM prompt risk
	granite3-guardian:8b                #  prompt guard ibm
	granite3-guardian:8b-q5_K_M         #  prompt guard ibm
	granite3-guardian:2b                #  prompt guard ibm
	granite3-guardian:2b-q8_0           #  prompt guard ibm
	aya-expanse                         # cohere
	aya-expanse:latest                  # cohere
	aya-expanse:8b                      # cohere model 128k content 23 languages
	aya-expanse:8b-q4_K_M               # cohere model 128k content 23 languages
	shieldgemma                         # google safety policies
	shieldgemma:latest                  # google safety policies
	shieldgemma:9b                      # safety of text prompts
	shieldgemma:9b-q4_K_M               # safety of text prompts
	shieldgemma:2b                      # safety of text prompts
	shieldgemma:2b-q4_K_M               # safety of text prompts
	llama-guard3                        # safety classification
	llama-guard3:latest                 # safety classification
	llama-guard3:8b                     # safety of prompts
	llama-guard3:8b-q4_K_M              # safety of prompts
	llama-guard3:1b                     # safety of prompts
	llama-guard3:1b-q8_0                # safety of prompts
	llama3.2                            # Meta 3.2-3B Q4 128 context
	llama3.2:latest                     # Meta 3.2-3B Q4 128 context
	llama3.2:3b                         # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:3b-instruct-q4_K_M         # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:1b                         # Meta 1B 128K context
	llama3.2:1b-instruct-q8_0           # Meta 1B 128K context
	qwen2.5-coder                       # Alibaba model
	qwen2.5-coder:latest                # 128K Tuned for coding 7B
	qwen2.5-coder:7b                    # 128K Tuned for coding 7B
	qwen2.5-coder:7b-instruct           # 128K Tuned for coding 7B
	qwen2.5-coder:7b-instruct-q4_K_M    # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b                  # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b-instruct         # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b-instruct-q8_0    # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b                  # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct         # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct         # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct-q4_K_M  # 128K Tuned for coding 7B

	# these models are pre llama3.2 and subject to deprecation
	nemotron-mini:4b            # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	nemotron-mini:latest        # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	qwen2.5                     # the larger Alibab models
	qwen2.5:latest              # 128K context Alibaba 2024-09-16 7b
	qwen2.5:7b                  # 128K context Alibaba 2024-09-16 7b
	qwen2.5:0.5b                # 128K context Alibaba 2024-09-16 7b
	qwen2.5:1.5b                # 128K context Alibaba 2024-09-16 7b
	qwen2.5:3b                  # 128K context Alibaba 2024-09-16 7b
	bespoke-minicheck           # Fact check 7B q4_K_M UT Austin
	bespoke-minicheck:latest    # Fact check 7B q4_K_M
	bespoke-minicheck:7b        # Fact check 7B q4_K_M
	bespoke-minicheck:7b-q4_K_M # Fact check 7B q4_K_M
	reader-lm                   # Just for HTML to  markdown conversion
	reader-lm:latest            # Just for HTML to  markdown conversion
	reader-lm:1.5b              # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:1.5b-q4_0         # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:0.5b              # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:0.5b-q4_0         # HTML to Markdown conversion 1.5B-q4_K_M
	minicpm-v                   # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:latest            # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:8b                # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:8b-2.6-q4_0       # mLLM visual too, ocr v2.6 ModelBest CN
	# these models are pre llama3.1 and are very close to gone
	gemma2                      # Google 9B Q4 5.4GB 8K context
	gemma2:latest               # Google 9B Q4 5.4GB 8K context
	gemma2:9b                   # Google 9B Q4 5.4GB 8K context
	gemma2:9b-instruct-q4_0     # Google 9B Q4 5.4GB 8K context
	gemma2:2b                   # Google 9B Q4 5.4GB 8K context
	gemma2:2b-instruct-q4_0     # Google 9B Q4 5.4GB 8K context
	bge-large                   # embedding model from BAAI
	bge-large:335m              # embedding model from BAA
	bge-large:335m-en-v1.5-fp16 # embedding model from BAA

)
#
# these are models which are under 10B parameters
log_verbose "loading all models over 9B parameters, requires >16GB RAM"
MODEL_MEDIUM+=(
	falcon3:10b                         # 7B parameters
	falcon3:10b-instruct-q4_K_M         # 7B parameters
	qwq                                 # like o1
	qwq:latest                          # like o1
	qwq:32b                             # Alibaba advanced reasoning
	qwq:32b-preview-q4_K_M              # Alibaba advanced reasoning
	llama3.2-vision                     # should run in open-webui
	llama3.2-vision:latest              # should run in open-webui
	llama3.2-vision:11b                 # vision works now
	llama3.2-vision:11b-instruct-q4_K_M # vision works now
	aya-expanse:32b                     # cohere model 128k content
	aya-expanse:32b-q4_K_M              # cohere model 128k content
	shieldgemma:27b                     # safety of text prompts
	shieldgemma:27b-q4_K_M              # safety of text prompts
	qwen2.5-coder:14b                   # 128K Tuned for coding 7B
	qwen2.5-coder:14b-instruct-q4_K_M   # 128K Tuned for coding 7B
	qwen2.5-coder:32b                   # 128K Tuned for coding 7B
	qwen2.5-coder:32b-instruct-q4_K_M   # 128K Tuned for coding 7B
	# these models are pre llama3.2 and are very close to gone
	solar-pro                             # single gpu model
	solar-pro:latest                      # 22b comparable to llama 3.1 70b 4k context
	solar-pro:22b                         # 22b comparable to llama 3.1 70b 4k context
	solar-pro:22b-preview-instruct-q4_K_M # 22b comparable to llama 3.1 70b 4k context
	qwen2.5:14b                           # 128K context Alibaba 2024-09-16 7b
	qwen2.5:32b                           # 128K context Alibaba 2024-09-16 7b
	gemma2:27b                            # old but only Google model
	gemma2:27b-instruct-q4_0              # old but only Google model

)

log_verbose "loading all models over 32B parameters, requires >64GB RAM"
MODEL_LARGE+=(
	llama3.3                            # same perforamnce as llama 3.1 405B
	llama3.3:latest                     # 128K context
	llama3.3:70b                        # 128K context
	llama3.3:70b-instruct-q4_K_M        # 128K context
	tulu3:70b                           # AI2 instruction following
	tulu3:70b-q4_K_M                    # AI2 instruction following
	llama3.2-vision:90b                 # vision works now
	llama3.2-vision:90b-instruct-q4_K_M # vision works now
	# these models are pre llama3.2 and are very close to gone
	nemotron                     # nvidia llama 3.1 but performs well
	nemotron:latest              # nvidia llama 3.1 obsolete soon
	nemotron:70b                 # nvidia tuned llama 3.1
	nemotron:70b-instruct-q4_K_M # nvidia tuned llama 3.1
	qwen2.5:72b                  # 128K context Alibaba 2024-09-16 7b
)

log_verbose "Extra modles if you have plenty of space"
MODEL_EXTRA+=(
	mixtral:8x7b                            # mistral moe (deprecated)
	athene-v2                               # nexusflow based on qwen2.5
	athene-v2:latest                        # code, math, log extraction
	athene-v2:72b                           # code, math, log extraction
	athene-v2:72b-q4_K_M                    # code, math, log extraction
	mistral-small                           # on the bubble to remove
	mistral-small:latest                    # v0.3 Mistral 22b-instruct-2409-q4_0
	mistral-small:22b                       # v0.3 Mistral 22b-instruct-2409-q4_0
	mistral-small:22b-instruct-2409-q4_0    # v0.3 Mistral 22b-instruct-2409-q4_0
	reflection                              # some cheating on the model
	reflection:latest                       # some cheating on the model
	reflection:70b                          # some cheating on the model
	reflection:70b-q4_0                     # some cheating on the model
	mistral-large                           # Mistral flagship Large 2
	mistral-large:latest                    # Mistral flagship
	mistral-large:123b                      # Mistral flagship
	mistral-large:123b-instruct-2411-q4_K_M # Mistral flagship
	yi-coder                                # 9B model q4 128K context
	yi-coder:latest                         # 9B model q4 128K context
	yi-coder:9b                             # 9B model q4 128K context
	yi-coder:9b-chat                        # 9B model q4 128K context
	yi-coder:9b-chat-q4_0                   # 9B model q4 128K context
	yi-coder:1.5b                           # 9B model q4 128K context
	yi-coder:1.5b-chat                      # 9B model q4 128K context
	yi-coder:1.5b-chat-q4_0                 # 9B model q4 128K context
	phi3.5                                  # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:latest                           # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:3.8b                             # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:3.8b-mini-instruct-q4_0          # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
)
#
# move the deprecated models here to make sure to delete them
MODELS_REMOVE+=(
	# succeeded by 3.1
	granite3-dense                    # IBM tool, RAG, code, translation
	granite3-dense:latest             # IBM
	granite3-dense:2b                 # RAG, code  generation, translation
	granite3-dense:2b-instruct-q4_K_M # RAG, code  generation, translation
	granite3-dense:8b                 # RAG, code  generation, translation
	granite3-dense:8b-instruct-q4_K_M # RAG, code  generation, translation
	granite3-moe                      # mixture of experts
	granite3-moe:latest               # low latency model
	granite3-moe:1b                   # low latency model
	granite3-moe:1b-instruct-q4_K_M   # low latency model
	granite3-moe:3b                   # larger model
	granite3-moe:3b-instruct-q4_K_M   # larger model
	# post llama3.2 but trying new vision models
	hermes3               # fine tuned llama 3.1 8B 128K context
	hermes3:70b           # fine tuned llama 3.1 q4 128K Context
	smollm                # small language models on device
	smollm:135m           # 135m is small
	smollm:1.7b           # deprecated by smollm2
	deepseek-v2.5         # 236B is way too big for a 64GB machine
	llama3.1              # deprecated
	llama3.1:8b-text-q4_0 # text tuned model poor results
	# models pre-llama3.1
	bge-large:335m # tokens to embeddings
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
	log_verbose "Include large models"
	MODEL_LIST+=("${MODEL_LARGE[@]}")
fi
if $INCLUDE_MEDIUM; then
	log_verbose "Include medium models"
	MODEL_LIST+=("${MODEL_MEDIUM[@]}")
fi
if $INCLUDE_HF; then
	log_verbose "Include HF models"
	MODEL_LIST+=("${MODEL_HF[@]}")
fi
if $INCLUDE_EXTRA; then
	log_verbose "Include extra models for >2TB drives"
	MODEL_LIST+=("${MODEL_EXTRA[@]}")
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

if pgrep ollama >/dev/null; then
	log_verbose "$ACTION on ${MODEL_LIST[*]}"
	ollama_action "$ACTION" "${MODEL_LIST[@]}"
	log_verbose "Removing deprecated models ${MODELS_REMOVE[*]}"
	ollama_action rm "${MODELS_REMOVE[@]}"
fi

if [[ -v OLLAMA_MODELS ]]; then
	log_verbose "Changing default storage of models to $OLLAMA_MODELS"
	if ! config_mark; then
		config_add <<-EOF
			if [ -z "\${OLLAMA_MODELS+x} ]; then OLLAMA_MODELS="$OLLAMA_MODELS"; fi
		EOF
	fi
fi

declare -A PYTHON_PACKAGE+=(
	["open-webui"]=3.12 # include the required python version
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
for package in "${!PYTHON_PACKAGE[@]}"; do
	pipx_install -p "${PYTHON_PACKAGE[$package]}" "$package"
done
# fi
#
log_verbose "install current shell completion"
open-webui --install-completion

PACKAGE+=(
)

log_verbose "installing ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

log_verbose "installing ollama environment variables to $WS_DIR/git/src/.envrc"
if ! config_mark "$WS_DIR/git/src/.envrc"; then
	config_add "$WS_DIR/git/src/.envrc" <<-EOF
		export OLLAMA_KV_CACHE_TYPE=q4_0
		export OLLAMA_FLASH_ATTENTION=1
	EOF
fi
# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc
log_warning "WEBUI_SECRET_KEY and OPENAI_API_KEY should both be defined before running ideally in a .envrc"
log_warning "Or put the API key into OpenWebUI"
log_verbose "To add Groq to OPen-webui Lower Left > Admin Panel > Settings > Connections > OpenAI API"
log_verbose "Click on + on he right and add URL https://api.groq.com/openai/v1 and your GROQ key"
# https://zohaib.me/extending-openwebui-using-pipelines/
# log_verbose "https://github.com/open-webui/pipelines"
log_verbose "To add Gemini, add functions or pipelines you need to run a docker and add it"
log_verbose 'docker run -d -p 9099:9099 --add-host=host.docker.internal:host-gateway \ '
log_verbose '-v pipelines:/app/pipelines --name pipelines --restart always \ '
log_verbose "ghcr.io/open-webui/pipelines:main"
log_verbose "or fork and submodule add git@githbu.com:open-webui/pipelines"
log_verbose "pip install - requirements.txt && sh .start.sh"

log_verbose "Installing the pipelines interface which allows compatible interfaces"
log_verbose "See https://github.com/open-webui/pipelines"
