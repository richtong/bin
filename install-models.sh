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

INCLUDE_XSMALL="${INCLUDE_XSMALL:-false}"
INCLUDE_SMALL="${INCLUDE_SMALL:-false}"
INCLUDE_MEDIUM="${INCLUDE_MEDIUM:-false}"
INCLUDE_LARGE="${INCLUDE_LARGE:-false}"
INCLUDE_XLARGE="${INCLUDE_XLARGE:-false}"
INCLUDE_GGUF="${INCLUDE_GGUF:-true}"
INCLUDE_MLX="${INCLUDE_MLX:-false}"
INCLUDE_OLD="${INCLUDE_OLD:-false}"
FORCE="${FORCE:-false}"
DISK_MAX="${DISK_MAX:-80}"
SHOW_SIZE="${SHOW_SIZE:-true}"

REMOVE_OBSOLETE="${REMOVE_OBSOLETE:-true}"

AUTOMATIC_BY_MEMORY="${AUTOMATIC_BY_MEMORY:-true}"
# if set to false will remove/uninstall models
ACTION="${ACTION:-pull}"

OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdveox:rlfsmugtiz" opt; do
	case "$opt" in
	h)
		cat <<EOF

Installs Ollama models and removes obsolete or large ones.
We do not pull modles if we have less than 20% disk free unless
-f is set

usage: $SCRIPTNAME [ flags ]
flags:
	-a $(! $AUTOMATIC_BY_MEMORY || echo "do not ")automatically install models based on system memory
	-d $(! $DEBUGGING || echo "no ")debugging
	-e $(! $INCLUDE_XLARGE || echo "do not ")pull extra models if you have lots of disk (>2TB)
	-f $(! $FORCE || echo "do not")force pull even if disk larger than (default DISK_MAX=$DISK_MAX)
	-g $(! $INCLUDE_GGUF || echo "do not ")pull huggingface models GGUF for Ollama
	-h help
	-i $(! $INCLUDE_MLX || echo "do not ")pull huggingface models GGUF for Ollama
	-l $(! $INCLUDE_LARGE || echo "do not ")pull larger then 32B+ parameters (even if you do not have 64GB+ RAM)
	-m $(! $INCLUDE_MEDIUM || echo "do not ")pull larger then 10B+ parameters (even if you do not have 32GB+ RAM)
	-o $(! $INCLUDE_OLD || echo "do not ")pull legacy models for comparisons
	-r $(! $REMOVE_OBSOLETE || echo "do not ")remove obsolete models
	-s $(! $INCLUDE_SMALL || echo "do not ")pull smaller then 7B+ parameters (even if you do not have 16GB+ RAM)
	-t $(! $INCLUDE_XSMALL || echo "do not ")pull smaller then 3B+ parameters (even if you do not have 8GB+ RAM)
	-u $([[ $ACTION == pull ]] || echo "un")install models
	-v $(! $VERBOSE || echo "not ")verbose
	-x storage location for models $([[ -v OLLAMA_MODELS ]] && echo default: "$OLLAMA_MODELS")
	-z $(! $SHOW_SIZE || echo "do not ")show size of the largest models

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
	t)
		# invert the variable when flag is set
		INCLUDE_XSMALL="$($INCLUDE_XSMALL && echo false || echo true)"
		export INCLUDE_XSMALL
		;;
	s)
		# invert the variable when flag is set
		INCLUDE_SMALL="$($INCLUDE_SMALL && echo false || echo true)"
		export INCLUDE_SMALL
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
	e)
		# invert action between pull and rm
		INCLUDE_XLARGE="$($INCLUDE_XLARGE && echo false || echo true)"
		export INCLUDE_XLARGE
		;;
	f)
		# invert the variable when flag is set
		INCLUDE_GGUF="$($INCLUDE_GGUF && echo false || echo true)"
		export INCLUDE_GGUF
		;;
	i)
		# invert the variable when flag is set
		INCLUDE_MLX="$($INCLUDE_MLX && echo false || echo true)"
		export INCLUDE_MLX
		;;
	o)
		# invert action between pull and rm
		INCLUDE_OLD="$($INCLUDE_OLD && echo false || echo true)"
		export INCLUDE_OLD
		;;
	r)
		# invert action between pull and rm
		REMOVE_OBSOLETE="$($REMOVE_OBSOLETE && echo false || echo true)"
		export REMOVE_OBSOLETE
		;;
	u)
		# invert action between pull and rm
		ACTION="$([[ $ACTION == pull ]] && echo rm || echo pull)"
		if [[ $ACTION == rm ]]; then
			echo "Removing models you must specify the exact ones -a is off"
			AUTOMATIC_BY_MEMORY=false
		fi
		export ACTION
		;;
	x)
		OLLAMA_MODELS="$OPTARG"
		export OLLAMA_MODELS
		;;

	z)
		SHOW_SIZE="$($SHOW_SIZE && echo false || echo true)"
		export SHOW_SIZE
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

# note things like neovim code companion will use the first model
# that comes out of ollama list and this is the last one pulled, so this
# pull order has the default at the bottom
# These are too large for a 64GB machine
# note we load latest and also the tagged version

# we put all the big models here if you are disk constrained
# now sorted by date added from ollama as of 11-15-24

# these are pre llama3.2 and subject to deprecation

# https://huggingface.co/mlx-community?message=You%27ve%20joined%20MLX%20Community!
# https://huggingface.co/models?library=mlx&sort=trending
MODEL_MLX+=(
	mlx-community/plamo-2-8b-4bit                           # PLaMO-13B Open source Japanese from PFN
	mlx-community/Violet-Lyra-Gutenberg-4bit                # # merged models
	mlx-community/Unsloth-DeepSeek-R1-Distill-Qwen-32B-4bit # 5B parameters
	mlx-community/DeepSeek-R1-Distill-Qwen-32B-abliterated  # try this one
	mlx-community/Qwen2.5-VL-72B-Instruct-4bit              # Visual input
	mlx-community/DeepSeek-R1-Distill-Llama-70B-4bit        # compare with ollama

)

MODEL_MLX_REMOVE+=(
	mlx-community/DeepSeek-R1-4bit           # 126B parameters
	mlx-community/perplexity-ai-r1-1776-4bit # do not if it will fit

)

# https://huggingface.co/models?library=gguf&sort=trending
MODEL_GGUF+=(
	hf.co/lmstudio-community/olmOCR-7B-0225-preview-GGUF:Q4_K_M
	hf.co/lmstudio-community/Qwen2-VL-7B-Instruct-GGUF
	hf.co/HYEONii/Qwen2-VL-7B-Q4_K_M-GGUF:Q4_K_M

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
log_verbose "Minimal Base 1-2B models for machines that <8GB"
MODEL+=(
	granite3.2:2b # reasoning model messages += []{role: control, content: thinking}]
	granite3.2:2b-instruct-q4_K_M
	deepscaler        # fintuned deepseek-r1-distilled-qwen beats 01-previe
	deepscaler:latest # 8K synthetic
	deepscaler:1.5b
	deepscaler:1.5b-preview-fp16
	deepseek-r1:1.5b                     # small model
	deepseek-r1:1.5b-qwen-distill-q4_K_M # small model
	smallthinker                         # Fine tuned Qwen2.5-b-instruct
	smallthinker:latest                  # qwq used to generate 8K synthetic
	opencoder                            # completely open source
	opencoder:latest                     # completely open source
	opencoder:1.5b                       #  english and chinse
	opencoder:1.5b-instruct-q4_K_M       #  english and chinse
	smollm2                              # open source
	smollm2:latest                       # open source
	smollm2:135m-instruct-q4_K_M         # 135m is small
	smollm2:1.7b                         # large is smarll
	smollm2:1.7b-instruct-q4_K_M         # large is smarll
	granite3-guardian:2b                 #  prompt guard ibm
	granite3-guardian:2b-q8_0            #  prompt guard ibm
	shieldgemma:2b                       # safety of text prompts
	shieldgemma:2b-q4_K_M                # safety of text prompts
	llama-guard3:1b                      # safety of prompts
	llama-guard3:1b-q8_0                 # safety of prompts
	llama3.2:1b                          # Meta 1B 128K context
	llama3.2:1b-instruct-q8_0            # Meta 1B 128K context
	qwen2.5-coder:0.5b                   # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b-instruct          # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b-instruct-q8_0     # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b                   # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct          # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct          # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct-q4_K_M   # 128K Tuned for coding 7B

	# these models are pre llama3.2 and subject to deprecation
	qwen2.5:0.5b # 128K context Alibaba 2024-09-16 7b
	qwen2.5:1.5b # 128K context Alibaba 2024-09-16 7b
	# these models are pre llama3.1 and are very close to gone
	bge-large                   # embedding model from BAAI
	bge-large:335m              # embedding model from BAA
	bge-large:335m-en-v1.5-fp16 # embedding model from BAA

)

log_verbose "loading all models over 2-3B parameters, requires >4GB of RAM"
MODEL_XSMALL+=(
	smallthinker:3b              # long sequence encourage CoT
	smallthinker:3b-preview-q8_0 # open dataset
	falcon3:3b                   # 7B parameters
	falcon3:3b-instruct-q4_K_M   # 7B parameters
	falcon3:1b                   # 7B parameters
	falcon3:1b-instruct-q8_0
	llama3.2                    # Meta 3.2-3B Q4 128 context
	llama3.2:latest             # Meta 3.2-3B Q4 128 context
	llama3.2:3b                 # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:3b-instruct-q4_K_M # Meta 3.2-3B Q4 128 context 2GB
	qwen2.5:3b                  # 128K context Alibaba 2024-09-16 7b
)

log_verbose "loading all models over 4-8B parameters, requires >8GB of RAM"
MODEL_SMALL+=(
	granite3.2 # thinking with message += [{ role: control, content: thinking}]
	granite3.2:latest
	granite3.2:8b
	granite3.2:8b-instruct-q4_K_M
	openthinker # resaonsing models based on deepseek-r1
	openthinker:latest
	openthinker:7b
	openthinker:7b-q4_K_M
	deepseek-r1:latest                  # 7b reasoning model
	deepseek-r1:7b                      # competitive to o1
	deepseek-r1:7b-qwen-distill-q4_K_M  # competitive to o1
	deepseek-r1:8b                      # llama distilled 8b
	deepseek-r1:8b-llama-distill-q4_K_M # q8b
	dolphin3                            # llama3.1 8B tuned
	dolphin3:latest                     # llama3.1 8B tuned
	dolphin3:8b                         # llama3.1 8B tuned
	dolphin3:8b-llama3.1-q4_K_M         # llama3.1 8B tuned
	marco-o1                            # Alibab open large reasoning
	marco-o1:latest                     # Alibab open large reasoning
	marco-o1:7b                         # 7b
	marco-o1:7b-q4_K_M                  # q4_K_M
	opencoder:8b                        # reproducible
	opencoder:8b-instruct-q4_K_M        # reproducible
	granite3-guardian                   # IBM prompt risk
	granite3-guardian:latest            # IBM prompt risk
	granite3-guardian:8b                #  prompt guard ibm
	granite3-guardian:8b-q5_K_M         #  prompt guard ibm
	shieldgemma                         # google safety policies
	shieldgemma:latest                  # google safety policies
	shieldgemma:9b                      # safety of text prompts
	shieldgemma:9b-q4_K_M               # safety of text prompts
	llama-guard3                        # safety classification
	llama-guard3:latest                 # safety classification
	llama-guard3:8b                     # safety of prompts
	llama-guard3:8b-q4_K_M              # safety of prompts
	qwen2.5-coder                       # Alibaba model
	qwen2.5-coder:latest                # 128K Tuned for coding 7B
	qwen2.5-coder:7b                    # 128K Tuned for coding 7B
	qwen2.5-coder:7b-instruct           # 128K Tuned for coding 7B
	qwen2.5-coder:7b-instruct-q4_K_M    # 128K Tuned for coding 7B
	qwen2.5                             # the larger Alibab models
	qwen2.5:latest                      # 128K context Alibaba 2024-09-16 7b
	qwen2.5:7b                          # 128K context Alibaba 2024-09-16 7b
	bespoke-minicheck                   # Fact check 7B q4_K_M UT Austin
	bespoke-minicheck:latest            # Fact check 7B q4_K_M
	bespoke-minicheck:7b                # Fact check 7B q4_K_M
	bespoke-minicheck:7b-q4_K_M         # Fact check 7B q4_K_M
	nemotron-mini:4b                    # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	nemotron-mini:latest                # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	minicpm-v                           # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:latest                    # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:8b                        # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:8b-2.6-q4_0               # mLLM visual too, ocr v2.6 ModelBest CN

)
#
log_verbose "loading all models over 9B-32B parameters, requires >16GB RAM"
MODEL_MEDIUM+=(
	openthinker:32b                        # dereict from deepseek-r1
	openthinker:32b-q4_K_M                 # fine tuned on openthoughts 114k dataset
	deepseek-r1:14b                        # r1 comparable
	deepseek-r1:14b-qwen-distill-q4_K_M    # r1 comparable
	deepseek-r1:32b                        # r1 comparable
	deepseek-r1:32b-qwen-distill-q4_K_M    # r1 comparable
	mistral-small                          # this is now the 2503 model
	mistral-small:latest                   # now the 2501 model
	mistral-small:24b-instruct-2501-q4_K_M # the latest model
	olmo2:13b                              # AI2 fully open
	olmo2:13b-1124-instruct-q4_K_M         # compets with llama 3.1
	phi4                                   # Microsoft Jan 7 2025
	phi4:latest                            # synthetic, filtered 9.1GB
	phi4:14b                               # 16K context length only
	phi4:14b-q4_K_M                        # MMLU equals llama3.3:70b qwen2.5:72b
	falcon3:10b                            # 7B parameters
	falcon3:10b-instruct-q4_K_M            # 7B parameters
	qwq                                    # like o1
	qwq:latest                             # like o1
	qwq:32b                                # Alibaba advanced reasoning
	qwq:32b-preview-q4_K_M                 # Alibaba advanced reasoning
	llama3.2-vision                        # should run in open-webui
	llama3.2-vision:latest                 # should run in open-webui
	llama3.2-vision:11b                    # vision works now
	llama3.2-vision:11b-instruct-q4_K_M    # vision works now
	qwen2.5-coder:14b                      # 128K Tuned for coding 7B
	qwen2.5-coder:14b-instruct-q4_K_M      # 128K Tuned for coding 7B
	qwen2.5-coder:32b                      # 128K Tuned for coding 7B
	qwen2.5-coder:32b-instruct-q4_K_M      # 128K Tuned for coding 7B
	# these models are pre llama3.2 and are very close to gone
	qwen2.5:14b # 128K context Alibaba 2024-09-16 7b
	qwen2.5:32b # 128K context Alibaba 2024-09-16 7b

)

log_verbose "loading all models over >32B parameters, requires >64GB RAM"
MODEL_LARGE+=(
	r1-1776                              # perplexity r1 model on latest data
	r1-1776:latest                       # perplexity r1 model on latest data
	r1-1776:70b-distill-llama-q4_K_M     # perplexity r1 model on latest data
	r1-1776:70b                          # perplexity r1 model on latest data
	deepseek-r1:70b                      # disitlled lllama
	deepseek-r1:70b-llama-distill-q4_K_M # llama based
	tulu3:70b                            # tulu3 is not much better than llama3 and takes speace
	tulu3:70b-q4_K_M                     # AI2 instruction following
	llama3.3                             # same perforamnce as llama 3.1 405B
	llama3.3:latest                      # 128K context
	llama3.3:70b                         # 128K context
	llama3.3:70b-instruct-q4_K_M         # 128K context
	llama3.2-vision:90b                  # vision works now
	llama3.2-vision:90b-instruct-q4_K_M  # vision works now
	# these models are pre llama3.2 and are very close to gone
	qwen2.5:72b # 128K context Alibaba 2024-09-16 7b
)

log_verbose "Extra models if you have plenty of space about to be obsolete"
MODEL_XLARGE+=(
	olmo2                         # Ai2 fully open model competitive
	olmo2:latest                  # competitive iwth llama 3.1
	olmo2:7b                      # November 26 2024 release
	command-r7b                   # command-r7b is the default
	command-r7b:latest            # latest
	command-r7b:7b                # 7B
	command-r7b:7b-12-2024-q4_K_M # Dec 2024
	falcon3
	falcon3:latest             # latest from Abu Dhabi
	falcon3:7b                 # 7B parameters
	falcon3:7b-instruct-q4_K_M # 7B parameters
	granite-embedding          # latest ibm embeddings
	granite-embedding:latest
	granite-embedding:30m
	granite-embedding:30m-en
	granite-embedding:278m
	granite-embedding:278m-fp16
	sailor2:8b                          # qwen  tuned for se asian languages
	sailor2:8b-chat-q4_K_M              # qwen  tuned for se asian languages
	snowflake-arctic-embed2             # new embeddings
	snowflake-arctic-embed2:latest      # new embeddings
	snowflake-arctic-embed2:568m-l-fp16 # new embeddings
	snowflake-arctic-embed2:568m        # new embeddings
	aya-expanse:32b                     # cohere model 128k content
	aya-expanse:32b-q4_K_M              # cohere model 128k content
	tulu3                               # AI2 instruction following
	tulu3:latest                        # full open source data, code, recipes
	tulu3:8b                            # 128 K content has 70B brother
	tulu3:8b-q4_K_M                     # standard quantization
	mixtral:8x7b                        # mistral moe (deprecated)
	athene-v2                           # nexusflow based on qwen2.5
	athene-v2:latest                    # code, math, log extraction
	athene-v2:72b                       # code, math, log extraction
	athene-v2:72b-q4_K_M                # code, math, log extraction

)

# legacy models for comparison with modern ones
MODEL_OLD+=(

	phi3                           # the original
	phi3.5                         # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:latest                  # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:3.8b                    # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:3.8b-mini-instruct-q4_0 # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	# early 2024 models
	llama2:7b           # original llama2
	llama2:13b          # 13b
	orca-mini:3b        # Microsoft Research
	falcon:7b           # abu dahbi TII
	mistral:7b          # v0.3 of original Mistral
	starcoder:1b        # another fined tuned model
	yi:6b               # yi 1.5
	deepseek-coder:6.7b # first deepseek
	orca2:7b            # Microsoft
	phi:2.7b            # phi-2
	qwen:7b             ## Qwen 1.5
)

# move the deprecated models here to make sure to delete them
MODEL_REMOVE+=(
	# GGUF models are too big
	hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-abliterated-GGUF
	hf.co/LatitudeGames/Wayfarer-Large-70B-Llama-3.3-GGUF # Role play oriented
	hf.co/bartowski/Qwen2-VL-72B-Instruct-GGUF:Q4_K_M
	# llama 3.2 models
	granite3.1-dense                     # IBM tool, RAG, code, translation
	granite3.1-dense:latest              # IBM
	granite3.1-dense:8b                  # RAG, code  generation, translation
	granite3.1-dense:8b-instruct-q4_K_M  # RAG, code  generation, translation
	granite3.1-dense:2b                  # do not need such a small model
	granite3.1-dense:2b-instruct-q4_K_M  # granite worse than llama
	granite3.1-moe                       # mixture of experts
	granite3.1-moe:latest                # low latency model
	granite3.1-moe:1b                    # low latency model
	granite3.1-moe:1b-instruct-q4_K_M    # low latency model
	granite3.1-moe:3b                    # larger model
	granite3.1-moe:3b-instruct-q4_K_M    # larger model
	mistral-small:22b                    # v0.3 Mistral 22b-instruct-2409-q4_0
	mistral-small:22b-instruct-2409-q4_0 # v0.3 Mistral 22b-instruct-2409-q4_0
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
	aya-expanse                       # cohere replaced by command-r
	aya-expanse:latest                # cohere
	aya-expanse:8b                    # cohere model 128k content 23 languages
	aya-expanse:8b-q4_K_M             # cohere model 128k content 23 languages
	reader-lm                         # Just for HTML to  markdown conversion
	reader-lm:latest                  # Just for HTML to  markdown conversion
	reader-lm:1.5b                    # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:1.5b-q4_0               # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:0.5b                    # HTML to Markdown conversion 1.5B-q4_K_M
	reader-lm:0.5b-q4_0               # HTML to Markdown conversion 1.5B-q4_K_M
	# pre llama3.2 but trying new vision models
	hermes3                      # fine tuned llama 3.1 8B 128K context
	hermes3:70b                  # fine tuned llama 3.1 q4 128K Context
	smollm                       # small language models on device
	smollm:135m                  # 135m is small
	smollm:1.7b                  # deprecated by smollm2
	deepseek-v2.5                # 236B is way too big for a 64GB machine
	nemotron                     # nvidia llama 3.1 but performs well
	nemotron:latest              # nvidia llama 3.1 obsolete soon
	nemotron:70b                 # nvidia tuned llama 3.1
	nemotron:70b-instruct-q4_K_M # nvidia tuned llama 3.1
	# circa llama 3.1 models
	solar-pro                               # single gpu model
	solar-pro:latest                        # 22b comparable to llama 3.1 70b 4k context
	solar-pro:22b                           # 22b comparable to llama 3.1 70b 4k context
	solar-pro:22b-preview-instruct-q4_K_M   # 22b comparable to llama 3.1 70b 4k context
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
	llama3.1                                # deprecated
	llama3.1:8b-text-q4_0                   # text tuned model poor results
	# models pre-llama3.1
	bge-large:335m # tokens to embeddings
	mistral-nemo
	mistral-nemo:12b         # 128k context 12b-instruct-2407-q4_0
	shieldgemma:27b          # safety of text prompts
	shieldgemma:27b-q4_K_M   # safety of text prompts
	gemma2                   # Google 9B Q4 5.4GB 8K context
	gemma2:latest            # Google 9B Q4 5.4GB 8K context
	gemma2:9b                # Google 9B Q4 5.4GB 8K context
	gemma2:9b-instruct-q4_0  # Google 9B Q4 5.4GB 8K context
	gemma2:2b                # Google 9B Q4 5.4GB 8K context
	gemma2:2b-instruct-q4_0  # Google 9B Q4 5.4GB 8K context
	gemma2:27b               # old but only Google model
	gemma2:27b-instruct-q4_0 # old but only Google model
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
	command-r-plus:104b-q2_K # 39GB Q2 with 128K context for enterprise
	command-r:35b            # 128K context 35b 19GB
	mixtral

)

if $AUTOMATIC_BY_MEMORY; then
	log_verbose "Automatic model load by memory"
	# https://superuser.com/questions/197059/mac-os-x-sysctl-get-total-and-free-memory-size
	# 2**30 is 1GB
	MEMORY="$(util_gpu_memory)"
	log_verbose "Memory size is ${MEMORY}GB"
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
	$((MEMORY > 16)))
		INCLUDE_SMALL=true
		;&
	$((MEMORY > 8)))
		INCLUDE_XSMALL=true
		;&
	esac
	log_verbose "automatic sets INCLUDE_MEDIUM=$INCLUDE_MEDIUM INCLUDE_LARGE=$INCLUDE_LARGE INCLUDE_SMALL=$INCLUDE_SMALL INCLUDE_XSMALL=$INCLUDE_XSMALL"
fi

MODEL_LIST=("${MODEL[@]}")
if $INCLUDE_XLARGE; then
	log_verbose "Include extra large models"
	MODEL_LIST+=("${MODEL_XLARGE[@]}")
fi
if $INCLUDE_LARGE; then
	log_verbose "Include large models"
	MODEL_LIST+=("${MODEL_LARGE[@]}")
fi
if $INCLUDE_MEDIUM; then
	log_verbose "Include medium models"
	MODEL_LIST+=("${MODEL_MEDIUM[@]}")
fi
if $INCLUDE_SMALL; then
	log_verbose "Include small models"
	MODEL_LIST+=("${MODEL_SMALL[@]}")
fi
if $INCLUDE_XSMALL; then
	log_verbose "Include extra small models"
	MODEL_LIST+=("${MODEL_XSMALL[@]}")
fi
if $INCLUDE_GGUF; then
	log_verbose "Include HF GGUF models"
	MODEL_LIST+=("${MODEL_GGUF[@]}")
fi
if $INCLUDE_OLD; then
	log_verbose "Include old models"
	MODEL_LIST+=("${MODEL_OLD[@]}")
fi

# usage: ollama_action [ pull | rm  | ls] [ models...]
ollama_action() {
	local action="$1"
	shift
	log_verbose "ollama action action=$action models=$*"
	if ! command -v ollama >/dev/null; then
		return 0
	fi

	for M in "$@"; do
		# if you want to pull but not enough room skip it unless forced
		log_verbose "$action model $M"
		if [[ $action == rm ]]; then
			if ! ollama ls "$M" | tail -n +2 | grep -q "^${M}[[:space:]]"; then
				log_verbose "$M already removed"
				continue
			fi
		elif [[ $action == pull ]]; then
			DISK_USED="$(df -k . | sed 1d | awk 'FNR == 1 {print $5}' | cut -f 1 -d "%")"
			log_verbose "ollama_action: FORCE=$FORCE action=$action DISK_USED=$DISK_USED DISK_MAX=$DISK_MAX"
			if $FORCE || [[ $action == pull ]] && ((DISK_USED > DISK_MAX)); then
				log_verbose "cannot pull $M $DISK_USED% used at most $DISK_MAX% allowed"
				continue
			fi
		fi
		if ! ollama "$action" "$M"; then
			log_warning "failed $?"
		fi
	done
}

if [[ -v OLLAMA_MODELS ]]; then
	log_verbose "Changing default storage of models to $OLLAMA_MODELS"
	if ! config_mark; then
		config_add <<-EOF
			if [ -z "\${OLLAMA_MODELS+x} ]; then OLLAMA_MODELS="$OLLAMA_MODELS"; fi
		EOF
	fi
fi

if ! pgrep ollama >/dev/null; then
	log_warning "ollama not running"
else
	log_verbose "testing to remove obsolete models (Remove_OBSOLETE=$REMOVE_OBSOLETE)"
	if $REMOVE_OBSOLETE; then
		log_verbose "Removing deprecated models ${MODEL_REMOVE[*]}"
		ollama_action rm "${MODEL_REMOVE[@]}"
	fi

	log_verbose "$ACTION on ${MODEL_LIST[*]}"
	ollama_action "$ACTION" "${MODEL_LIST[@]}"

fi

if $INCLUDE_MLX; then

	if $REMOVE_OBSOLETE; then
		huggingface-cli delete-cache
	fi
	log_verbose "Include HF MLX models"
	huggingface-cli download "${MODEL_MLX[@]}"
fi

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

log_verbose "Installing the pipelines interface which allows compatible interfaces"
log_verbose "See https://github.com/open-webui/pipelines"

if $SHOW_SIZE; then
	log_verbose "Ollama.com models"
	for size in GB MB; do
		ollama ls | grep "$size" | sort -nruk 3
	done
	log_verbose "Ollama models from Huggingface cache"
	huggingface-cli scan-cache | tail -n +3 | sort -unk 3
	log_verbose "Exo MLX models"
	du -sh "${EXO_HOME:-"$HOME/cache/exo/downloads"}"/* | sort -n

fi
