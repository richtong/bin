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

INCLUDE_TOOL="${INCLUDE_TOOL:-false}"
INCLUDE_VISION="${INCLUDE_VISION:-false}"
INCLUDE_GGUF="${INCLUDE_GGUF:-false}"
INCLUDE_MLX="${INCLUDE_MLX:-false}"
EXO_HOME="${EXO_HOME:-"$HOME/.cache/exo/downloads"}"
OLLAMA_MODELS="${OLLAMA_MODELS:-"$HOME/.ollama/models"}"
OLLAMA_API_BASE="${OLLAMA_API_BASE:-"http://localhost:11434"}"

DRYRUN="${DRYRUN:-false}"
FORCE="${FORCE:-false}"
DISK_MAX="${DISK_MAX:-80}"
SHOW_SIZE="${SHOW_SIZE:-true}"
REMOVE_OBSOLETE_AND_OLD="${REMOVE_OBSOLETE_AND_OLD:-true}"
AUTOMATIC_BY_MEMORY="${AUTOMATIC_BY_MEMORY:-true}"
# The Ollama default is leave 25% free
MEMORY_RESERVED=${MEMORY_RESERVED:-0.2}
ACTION="${ACTION:-pull}"

INCLUDE_OLD="${INCLUDE_OLD:-false}"
INCLUDE_XSMALL="${INCLUDE_XSMALL:-false}"
INCLUDE_SMALL="${INCLUDE_SMALL:-false}"
INCLUDE_MEDIUM="${INCLUDE_MEDIUM:-false}"
INCLUDE_LARGE="${INCLUDE_LARGE:-false}"
INCLUDE_XLARGE="${INCLUDE_XLARGE:-false}"
INCLUDE_MEGA="${INCLUDE_MEGA:-false}"

OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvgltsafnzrexu0123456" opt; do
	case "$opt" in
	h)
		cat <<EOF
Installs Ollama models and removes obsolete or large ones.
We do not pull modles if we have less than 20% disk free unless
-f is set

usage: $SCRIPTNAME [ flags ]
flags:
	-h help
	-v $(! $VERBOSE || echo "no ")verbose output
	-d $(! $DEBUGGING || echo "no ")debugging

	speciality models:
	-g $(! $INCLUDE_GGUF || echo "do not ")pull huggingface models GGUF for Ollama
	-l $(! $INCLUDE_MLX || echo "do not ")pull huggingface models GGUF for Ollama
	-t $(! $INCLUDE_TOOL || echo "do not ")pull Tool using models for ollama
	-s $(! $INCLUDE_VISION || echo "do not ")pull Vision models for ollama

	models install parameters
	-a $(! $AUTOMATIC_BY_MEMORY || echo "do not ")automatically install models based on system memory
	-e Reserve memory for other processes (default: $((MEMORY_RESERVED * 100)))
	-f $(! $FORCE || echo "do not")force pull even if disk larger than (default DISK_MAX=$DISK_MAX)
	-n $(! $DRYRUN || echo "do not")dry run the commands
	-z $(! $SHOW_SIZE || echo "do not ")show size of the largest models
	-r $(! $REMOVE_OBSOLETE_AND_OLD || echo "do not ")remove obsolete (and old models if -o not set)
	-x storage location for models $([[ -v OLLAMA_MODELS ]] && echo default: "$OLLAMA_MODELS")
	-u $([[ $ACTION == pull ]] || echo "un")install models

	-o $(! $INCLUDE_OLD || echo "do not ")pull legacy models for comparisons
	-5 $(! $INCLUDE_MEGA || echo "do not ")pull larger then 32B+ parameters (even if you do not have 64GB+ RAM)
	-4 $(! $INCLUDE_XLARGE || echo "do not ")pull larger then 32B+ parameters (even if you do not have 64GB+ RAM)
	-3 $(! $INCLUDE_LARGE || echo "do not ")pull larger then 32B+ parameters (even if you do not have 64GB+ RAM)
	-2 $(! $INCLUDE_MEDIUM || echo "do not ")pull larger then 10B+ parameters (even if you do not have 32GB+ RAM)
	-1 $(! $INCLUDE_SMALL || echo "do not ")pull smaller then 7B+ parameters (even if you do not have 16GB+ RAM)
	-0 $(! $INCLUDE_XSMALL || echo "do not ")pull smaller then 3B+ parameters (even if you do not have 8GB+ RAM)

example of manual: Uninstall large and medium models and hugging face models
	$SCRIPTNAME -u -l -m -h

EOF
		exit 0
		;;
	d)
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;&
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	g)
		INCLUDE_GGUF="$($INCLUDE_GGUF && echo false || echo true)"
		;;
	l)
		INCLUDE_MLX="$($INCLUDE_MLX && echo false || echo true)"
		;;
	t)
		INCLUDE_TOOL="$($INCLUDE_TOOL && echo false || echo true)"
		;;
	s)
		INCLUDE_VISION="$($INCLUDE_VISION && echo false || echo true)"
		;;

	a)
		AUTOMATIC_BY_MEMORY="$($AUTOMATIC_BY_MEMORY && echo false || echo true)"
		;;
	e)
		MEMORY_RESERVED="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		;;
	n)
		DRYRUN="$($DRYRUN && echo false || echo true)"
		;;
	z)
		SHOW_SIZE="$($SHOW_SIZE && echo false || echo true)"
		;;
	r)
		REMOVE_OBSOLETE_AND_OLD="$($REMOVE_OBSOLETE_AND_OLD && echo false || echo true)"
		;;
	x)
		OLLAMA_MODELS="$OPTARG"
		;;
	u)
		ACTION="$([[ $ACTION == pull ]] && echo rm || echo pull)"
		if [[ $ACTION == rm ]]; then
			echo "Removing models you must specify the exact ones -a is off"
			AUTOMATIC_BY_MEMORY=false
		fi
		;;

	0)
		INCLUDE_OLD="$($INCLUDE_OLD && echo false || echo true)"
		;;
	1)
		INCLUDE_XSMALL="$($INCLUDE_XSMALL && echo false || echo true)"
		;;
	2)
		INCLUDE_SMALL="$($INCLUDE_SMALL && echo false || echo true)"
		;;
	3)
		INCLUDE_MEDIUM="$($INCLUDE_MEDIUM && echo false || echo true)"
		;;

	4)
		INCLUDE_LARGE="$($INCLUDE_LARGE && echo false || echo true)"
		;;
	5)
		INCLUDE_XLARGE="$($INCLUDE_XLARGE && echo false || echo true)"
		;;
	6)
		INCLUDE_XLARGE="$($INCLUDE_XLARGE && echo false || echo true)"
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
MODEL_MLX_SMALL+=(
)
# <=32B
MODEL_MLX_MEDIUM+=(
)
# <=90B
MODEL_MLX_LARGE+=(
)
MODEL_MLX_XLARGE+=(
)
MODEL_MLX_MEGA+=(
)
MODEL_MLX_REMOVE+=(
	mlx-community/Qwen3-30B-A3B-mixed-3-4bit
	mlx-community/DeepSeek-R1-Distill-Qwen-7B-4bit
	mlx-community/DeepSeek-R1-Distill-Llama-70B-4bit
	mlx-community/gemma-3-27b-pt-4bit
	mlx-community/QwQ-32B-4bit
	mlx-community/Mistral-Small-24B-Instruct-2501-4bit
	mlx-community/DeepSeek-R1-Distill-Qwen-32B-4bit
	mlx-community/Qwen2.5-VL-7B-Instruct-4bit
	mlx-community/Molmo-7B-D-0924-4bit
	mlx-community/OLMoE-1B-7B-0125-Instruct-4bit
	mlx-community/olmOCR-7B-0225-preview-4bit
	mlx-community/OLMoE-1B-7B-0125-Instruct
	mlx-community/UI-TARS-7B-SFT-4bit # Bytedance
	mlx-community/Qwen2.5-VL-72B-Instruct-4bit
	mlx-community/Llama-3.3-70B-Instruct-4bit
	mlx-community/Qwen2.5-Coder-14B-Instruct-abliterated-4bit
	mlx-community/DeepSeek-R1-4bit                          # 126B parameters
	mlx-community/DeepSeek-R1-Distill-Llama-70B-4bit        # compare with ollama
	mlx-community/DeepSeek-R1-Distill-Qwen-32B-abliterated  # try this one
	mlx-community/Qwen2.5-VL-72B-Instruct-4bit              # Visual input
	mlx-community/Unsloth-DeepSeek-R1-Distill-Qwen-32B-4bit # 5B parameters
	mlx-community/Violet-Lyra-Gutenberg-4bit                # # merged models
	mlx-community/gemma-3-4b-pt-4bit
	mlx-community/perplexity-ai-r1-1776-4bit # do not if it will fit
	mlx-community/plamo-2-8b-4bit            # PLaMO-13B Open source Japanese from PFN
)

# https://huggingface.co/models?library=gguf&sort=trending
# deprecate this for ollama.com available models
MODEL_GGUF+=(
	unsloth/Qwen3-30B-A3B-128K-GGUF
)
# these models do not load in ollama for some reason, maybe they are sharded
MODEL_GGUF_REMOVE+=(
	hf.co/lmstudio-community/Qwen2-VL-7B-Instruct-GGUF
	hf.co/lmstudio-community/Qwen2-VL-7B-Instruct-GGUF:latest
	hf.co/HYEONii/Qwen2-VL-7B-Q4_K_M-GGUF:Q4_K_M
	hf.co/lmstudio-community/olmOCR-7B-0225-preview-GGUF:Q4_K_M
)

MODEL_AUDIO+=(
	# https://developers.googleblog.com/en/introducing-gemma-3n-developer-guide/
	gemma3n:e2b-it-q4_K_M # https://ai.google.dev/gemma/docs/gemma-3n 5B with 2B minimum
	gemma3n:e4b-it-q4_K_M # Matformer and conditional parameter loading effective 4B actual 8B
)

MODEL_VISION+=(
	gemma3n:e2b-it-q4_K_M # https://ai.google.dev/gemma/docs/gemma-3n 5B with 2B minimum
	gemma3n:e4b-it-q4_K_M
	qwen2.5vl:32b-q4_K_M
	mistral-small3.1:24b-instruct-2503-q4_K_M
	gemma3:27b-it-q4_K_M
	gemma3:12b-it-q4_K_M
	granite3.2-vision:2b-q4_K_M
	llama3.2-vision:11b-instruct-q4_K_M # vision works now
	llama3.2-vision:90b-instruct-q4_K_M # vision works now
)

# Tool using models https://ollama.com/search?c=tools&o=newest
MODEL_TOOL+=(
	devstral:24b-small-2505-q4_K_M
	qwen3:0.6b-q4_K_M
	qwen3:1.7b-q4_K_M
	qwen3:4b-q4_K_M
	qwen3:8b-q4_K_M
	qwen3:14b-q4_K_M
	qwen3:30b-a3b_q4_K_M
	qwen3:32b-q4_K_M
	qwen3:235b-q4_K_M
	JollyLlama/GLM-4-32B-0414-Q4_K_M
	granite3.3:2b
	granite3.3:8b
	mistral-small3.1:24b-instruct-2503-q4_K_M
	cogito:3b-v1-preview-llama-q4_K_M
	cogito:8b-v1-preview-llama-q4_K_M
	cogito:14b-v1-preview-qwen-q4_K_M
	cogito:32b-v1-preview-qwen-q4_K_M
	cogito:70b-v1-preview-llama-q4_K_M
	llama4:17b-maverick-128e-instruct-q4_K_M
	llama4:17b-scout-16e-instruct-q4_K_M
	# command-a:111b-03-2025-q4_K_M
	phi4-mini:3.8b-q4_K_M
	llama3.3:70b-instruct-q4_K_M
)

MODEL_REASONING+=(
	magistral:24b-small-2506-q4_K_M
	qwen3:0.6b-q4_K_M
	qwen3:1.7b-q4_K_M
	qwen3:4b-q4_K_M
	qwen3:8b-q4_K_M
	qwen3:14b-q4_K_M
	qwen3:30b-a3b_q4_K_M # 3b active parameters moe
	qwen3:32b-q4_K_M
	qwen3:235b-q4_K_M
	phi4-mini-reasoning:3.8b-q4_K_M
	phi4-reasoning:14b-q4_K_M
	phi4-reasoning:14b-plus-q4_K_M
	cogito:3b-v1-preview-llama-q4_K_M
	cogito:8b-v1-preview-llama-q4_K_M
	cogito:14b-v1-preview-qwen-q4_K_M
	cogito:32b-v1-preview-qwen-q4_K_M
	cogito:70b-v1-preview-llama-q4_K_M
	deepcoder:1.5b-preview-q4_K_M
	deepcoder:14b-preview-q4_K_M
	exaone-deep:2.4b-q4_K_M
	exaone-deep:32b-q4_K_M
	exaone-deep:7.8b-q4_K_M
	deepscaler:1.5b-preview-fp16
	openthinker:32b-q4_K_M
	openthinker:7b-q4_K_M
	JollyLlama/GLM-Z1-32B-0414-Q4_K_M
	deepseek-r1:1.5b-qwen-distill-q4_K_M
	deepseek-r1:14b-qwen-distill-q4_K_M
	deepseek-r1:32b-qwen-distill-q4_K_M
	deepseek-r1:671b-q4_K_M
	deepseek-r0:70b-llama-distill-q4_K_M
	deepseek-r1:7b-qwen-distill-q4_K_M
	deepseek-r1:8b-llama-distill-q4_K_M
)

MODEL_MOE+=(
	qwen3:30b-a3b-q4_K_M
	milkey/Qwen3-UD:235B-Q2_K_XL
	llama4:17b-maverick-128e-instruct-q4_K_M
	llama4:17b-scout-16e-instruct-q4_K_M
)

# two new datasets how much memory does a model take and how much context do
# they support. This uses fuzzy matching so you don't have to duplicate every
# tag, it does long string matches
declare -A MODEL_MEM+=(
	["gemma3n:e2b-it-q4_K_M"]=5.6
	["gemma3n:e4b-it-q4_K_M"]=7.5
	["magistral:24b-small-2506-q4_K_M"]=14
	["devstral:24b-small-2505-q4_K_M"]=14
	["qwen2.5vl:7b-q4_K_M"]=6
	["qwen2.5vl:32b-q4_K_M"]=38
	["qwen2.5vl:72b-q4_K_M"]=71
	["llama4:17b-maverick-128e-instruct-q4_K_M"]=67
	["llama4:17b-scout-16e-instruct-q4_K_M"]=245
	["phi4-mini:3.8b-q4_K_M"]=2.5
	["phi4-mini-reasoning:3.8b-q4_K_M"]=3.2
	["phi4-reasoning:14b-q4_K_M"]=11
	["phi4-reasoning:14b-plus-q4_K_M"]=11
	["phi4:14b-q4_K_M"]=9.1 # no tool calling
	["qwen3:0.6b-q4_K_M"]=0.5
	["qwen3:1.7b-q4_K_M"]=1.4
	["qwen3:4b-q4_K_M"]=2.6
	["qwen3:8b-q4_K_M"]=5.2
	["qwen3:14b-q4_K_M"]=9.3
	["qwen3:30b-a3b-q4_K_M"]=19
	["qwen3:32b-q4_K_M"]=20
	["qwen3-235b-a22b-128k:ud-q4_k_xl"]=134
	["qwen3:235b-a22b-q4_K_M"]=142
	["milkey/Qwen3-UD:235B-Q2_K_XL"]=88
	["gemma3:1b-it-q4_K_M"]=0.8
	["gemma3:4b-it-q4_K_M"]=3.3
	["gemma3:12b-it-q4_K_M"]=12.2
	["gemma3:27b-it-q4_K_M"]=17
	["deepcoder:1.5b-preview-q4_K_M"]=1.1
	["deepcoder:14b-preview-q4_K_M"]=9
	["deepscaler:1.5b-preview-fp16"]=3.6
	["deepseek-r1:1.5b-qwen-distill-q4_K_M"]=1.1
	["deepseek-r1:14b-qwen-distill-q4_K_M"]=9
	["deepseek-r1:32b-qwen-distill-q4_K_M"]=20
	["deepseek-r1:671b-q4_K_M"]=404
	["deepseek-r1:70b-llama-distill-q4_K_M"]=43 # llama based
	["deepseek-r1:7b-qwen-distill-q4_K_M"]=4.7  # competitive to o1
	["deepseek-r1:8b-llama-distill-q4_K_M"]=4.9
	["exaone-deep:2.4b-q4_K_M"]=1.6
	["exaone-deep:32b-q4_K_M"]=19
	["exaone-deep:7.8b-q4_K_M"]=4.8
	["shieldgemma:2b-q4_K_M"]=1.7 # safety of text prompts
	["tulu3:70b-q4_K_M"]=4.8      # AI2 instruction following
	["tulu3:8b-q4_K_M"]=43        # standard quantization
	["cogito:14b-v1-preview-qwen-q4_K_M"]=9
	["cogito:32b-v1-preview-qwen-q4_K_M"]=20
	["cogito:3b-v1-preview-llama-q4_K_M"]=2.2
	["cogito:8b-v1-preview-llama-q4_K_M"]=4.9
	["cogito:70b-v1-preview-llama-q4_K_M"]=43
	["command-a:111b-03-2025-q4_K_M"]=67 # 256K token context
	["gemma3:12b-it-q4_K_M"]=8.1
	["granite3.2-vision:2b-q4_K_M"]=2.4
	["granite3.3:2b"]=1.5
	["granite3.3:8b"]=4.9
	["JollyLlama/GLM-4-32B-0414-Q4_K_M"]=20 # GLM-4 32K Q4
	["rhundt/GLM-4-0414-32b-128k-Q4_K_M"]=20
	["llama-guard3:1b-q8_0"]=1.6                # safety of prompts
	["llama-guard3:8b-q4_K_M"]=4.9              # safety of prompts
	["llama3.2-vision:11b-instruct-q4_K_M"]=7.9 # vision works now
	["llama3.2-vision:90b-instruct-q4_K_M"]=55  # vision works now
	["llama3.3:70b-instruct-q4_K_M"]=43         # 128K context
	["lsm03624/GLM-Z1-32B-0414-Q4_K_M"]=20      # Zhipu GLM-Z1 reasoning add <think>\n  4k context? -rumination is deep research not available yet
	["mistral-small3.1:24b-instruct-2503-q4_K_M"]=15
	["olmo2:7b-1124-instruct-q4_K_M"]=4.5  # compets with llama 3.1
	["olmo2:13b-1124-instruct-q4_K_M"]=8.4 # compets with llama 3.1
	["opencoder:8b-instruct-q4_K_M"]=4.7   # reproducible
	["openthinker:32b-q4_K_M"]=20          # fine tuned on openthoughts 114k dataset2
	["openthinker:7b-q4_K_M"]=4.7
	["bespoke-minicheck:7b-q4_K_M"]=4.7 # Fact check 7B q4_K_M
)

# the context length maximum of models in 000s tokens
# for models that are close, put the more specfiic one first
# search top most first
declare -A MODEL_CONTEXT+=(
	["gemma3n:e2b-it-q4_K_M"]=32
	["gemma3n:e2b-it-q4_K_M"]=32
	["magistral"]=39
	["devstral"]=128
	["qwen2.5vl"]=128
	["qwen3"]=40
	["milkey/Qwen3-UD"]=40
	["granite3.2-vision"]=16
	["granite3.3"]=128
	["deepcoder"]=128
	["cogito"]=128
	["deepseek-r1"]=128
	["deepseek"]=128
	["exaone-deep"]=32
	["gemma3:1b"]=32
	["gemma3"]=128
	["deepscaler"]=128
	["bestspoke-minicheck"]=32
	["command-a"]=16
	["llama-guard3"]=128
	["llama3.2-vision"]=128
	["llama3.3"]=128
	["mistral-small3.1"]=128
	["JollyLlama/GLM-4-32B-0414-Q4_K_M"]=32
	["JollyLlama/GLM-Z1-32B-0414-Q4_K_M"]=32
	["lsm03624/GLM-Z1-32B-0414-Q4_K_M"]=32    # Zhipu GLM-Z1 reasoning add <think>\n  4k context? -rumination is deep research not available yet
	["rhundt/GLM-4-0414-32b-128k-Q4_K_M"]=128 # Rope scaling 4x or 32K base
	["olmo"]=4
	["opencoder:1.5b"]=4
	["opencoder:8b"]=8
	["openthinker"]=32
	["phi4-mini"]=4
	["phi4-mini-reasoning"]=4
	["phi4-reasoning"]=32
	["phi4"]=16
	["shield-gemma"]=8
	["tulu3"]=128
	["default"]=16
)

# memory used  per 32K tokens
declare -A MODEL_CONTEXT_MEM+=(
	["gemma"]=12
	["default"]=6
)

# These are kept in most recent first from https://ollama.com/search?o=newest
# These models fit in 64GB and are less than 30B parameters
# https://github.com/ggerganov/llama.cpp/discussions/2094
# https://github.com/ggerganov/llama.cpp/pull/1684
# https://en.wikipedia.org/wiki/Perplexity
# Perplexity of 247 means for each word, you have 247 guesses
# K quantization so Q4_K is type 1 auanitzation with 8 blocks using 4.5bpw
# q4 - 4 bit quantization of original floating point 16-bit model
# S, M or L - Small, Medium, Large which tellls you what Q you are
# using so Q4_K_M usts Q6_K for half the attention and feed forward
# To see the tradeoff for a 7B model, the perplexity (lower is better in bits
# per word and you can see why Q4_K_M is the default, at the knee of the curve
# 7B | F16 | Q2_K | Q3_K_M | Q4_K_M | Q5_K_M | Q6_K
# perplexity | 5.9066 | 6.4571 | 5.9061 | 5.9208 | 5.9110
log_verbose "Minimal Base <=2B models for machines that <=4GB GPU Memory"
MODEL+=(
	gemma3:1b-it-q4_K_M
	gemma3n:e2b-it-q4_K_M
	granite3.3:2b # reasoning model messages += []{role: control, content: thinking}]
	granite3.2-vision:2b-q4_K_M
	shieldgemma:2b-q4_K_M # safety of text prompts
)

log_verbose "loading all models >2B and <=4B parameters, requires >=8GB of RAM"
MODEL_XSMALL+=(
	gemma3n:e2b-it-q4_K_M
	gemma3:4b-it-q4_K_M
	qwen3:1.7b-q4_K_M
	phi4-mini-reasoning:3.8b-q4_K_M
)

log_verbose "loading all models >4-8B parameters, requires >=16GB of RAM"
MODEL_SMALL+=(
	qwen2.5vl:7b-q4_K_M # lateste aliababa vision model
	qwen3:4b-q4_K_M
	qwen3:8b-q4_K_M
	exaone-deep:7.8b-q4_K_M
	granite3.3:8b
	deepseek-r1:7b-qwen-distill-q4_K_M # competitive to o1
)

log_verbose "loading all models over 9B-32B parameters, requires >=32GB RAM"
MODEL_MEDIUM+=(
	magistral:24b-small-2506-q4_K_M
	devstral:24b-small-2505-q4_K_M
	qwen2.5vl:32b-q4_K_M
	phi4-reasoning:14b-plus-q4_K_M
	qwen3:14b-q4_K_M
	qwen3:30b-a3b-q4_K_M
	qwen3:32b-q4_K_M
	exaone-deep:32b-q4_K_M            # Korean need to use more
	JollyLlama/GLM-Z1-32B-0414-Q4_K_M # zhipu model need to  use more
	rhundt/GLM-4-0414-32b-128k-Q4_K_M # Rope scaling 4x or 32K base
	deepcoder:14b-preview-q4_K_M
	mistral-small3.1:24b-instruct-2503-q4_K_M
	cogito:32b-v1-preview-qwen-q4_K_M   # finetuned qwen
	gemma3:12b-it-q4_K_M                # 12B
	gemma3:27b-it-q4_K_M                # 12B
	deepseek-r1:14b-qwen-distill-q4_K_M # r1 comparable
	deepseek-r1:32b-qwen-distill-q4_K_M # r1 comparable
	phi4:14b-q4_K_M                     # no tool calling
	llama3.2-vision:11b-instruct-q4_K_M # vision works now
)

log_verbose "loading all models over >32B-90B parameters, requires >=64GB RAM"
MODEL_LARGE+=(
	qwen2.5vl:72b-q4_K_M
)

log_verbose "Extra models over 100B parameters, requires >=128GB"
MODEL_XLARGE+=(
	llama4:17b-scout-16e-instruct-q4_K_M
)

log_verbose "Megalarge models over 400B parameters requires >=256GB"
MODEL_MEGA+=(
	llama4:17b-maverick-128e-instruct-q4_K_M
	qwen3:235b-a22b-q4_K_M
	deepseek-r1:641b-q4_K_M # 641B
)

# move the deprecated models here to make sure to delete them
MODEL_REMOVE+=(
	milkey/Qwen3-UD:235B-Q2_K_XL         # too big and do not  use much
	deepseek-r1:70b-llama-distill-q4_K_M # llama based
	llama3.3:70b-instruct-q4_K_M         # 128K context
	llama3.2-vision:90b-instruct-q4_K_M  # vision works now
	llama-guard3:8b-q4_K_M               # safety of prompts
	JollyLlama/GLM-4-32B-0414-Q4_K_M
	deepseek-r1:8b-llama-distill-q4_K_M # q8b
	bespoke-minicheck:7b-q4_K_M         # Fact check 7B q4_K_M
	deepscaler:1.5b-preview-fp16
	llama-guard3:1b-q8_0                 # safety of prompts
	openthinker:32b-q4_K_M               # fine tuned on openthoughts 114k dataset
	openthinker:7b-q4_K_M                # return gibberish
	lsm03624/GLM-Z1-32B-0414-Q4_K_M      # Zhipu GLM-Z1 reasoning add <think>\n  4k context? -rumination is deep research not available yet
	olmo2:7b-1124-instruct-q4_K_M        # compets with llama 3.1
	deepseek-r1:1.5b-qwen-distill-q4_K_M # small model
	opencoder:8b-instruct-q4_K_M         # reproducible
	tulu3:8b-q4_K_M                      # standard quantization
	exaone-deep:2.4b-q4_K_M
	phi4-mini:3.8b-q4_K_M
	olmo2:13b-1124-instruct-q4_K_M # compets with llama 3.1
	phi4-reasoning:14b-q4_K_M
	tulu3:70b-q4_K_M                 # AI2 instruction following
	sammcj/glm-4-32b-0414            # Q6_K 32K context
	JollyLlama/GLM-4-32B-0414-Q4_K_M # GLM-4 32K Q4
	deepseek-r1:latest               # 7b reasoning model
	deepseek-r1:7b                   # not tool calling
	deepseek-r1:8b                   # llama distilled 8b
	opencoder:8b                     # reproducible
	packeting/Qwen2.5-VL-32B-Instruct:latest
	deepseek-r1:32b
	opencoder:8b
	deepseek-r1:8b
	deepseek-r1:7b
	deepseek-r1:latest
	granite3-guardian:2b-q8_0
	cogito:3b-v1-preview-llama-q4_K_M # Deep Cogito tool too
	cogito:8b
	cogito:8b-v1-preview-llama-q4_K_M # trained with Iterated Distillation and Amplification
	cogito:3b
	cogito:14b-v1-preview-qwen-q4_K_M  # finetuned qwen
	cogito:70b:v1-preview-llama-q4_K_M # finetuned llama
	qwen3:latest
	phi4-mini:latest
	gemma3:4b
	exaone-deep:2.4b
	Drews54/llama3.2-vision-abliterated:latest
	bge-large:latest b3d71c928059
	aravhawk/llama4:400b            # llama 4 scout
	aravhawk/llama4:maverick-q4_K_M # 1M context
	aravhawk/llama4:400b            # llama 4 scout
	aravhawk/llama4:maverick-q4_K_M # 1M context
	aravhawk/llama4:109b            # 17b x 16 experts
	aravhawk/llama4:scout-q4_K_M    # 10M token context
	gnieranite3-guardian:2b         #  prompt guard ibm
	deepseek-r1:1.5b                # small model
	shieldgemma:2b                  # safety of text prompts
	llama-guard3:1b                 # safety of prompts
	granite3.2-vision
	granite3.2-vision:latest
	granite3.2-vision:2b
	deepscaler        # fintuned deepseek-r1-distilled-qwen beats 01-previe
	deepscaler:latest # 8K synthetic
	deepscaler:1.5b
	qwen3:0.6b-q4_K_M
	qwen3:0.6b
	qwen3:1.7b
	cogito
	phi4-mini      # latest from Microsoft
	phi4-mini:3.8b # tool calling
	gemma3         # vision model
	gemma3:latest
	granite3.3 # thinking with message += [{ role: control, content: thinking}]
	granite3.3:latest
	openthinker        # resaonsing models based on deepseek-r1
	openthinker:latest # not tool calling
	openthinker:7b
	qwen3:4b
	qwen3
	qwen3:8b
	cogito           # set to reasoning with /set system ""Enable deep thinking subroutine."""
	cogito:latest    # 128K context, 30 lanugages
	exaone-deep:7.8b # LG AI
	exaone-deep:32b  # LG AI
	deepseek-r1:14b  # r1 comparable
	gemma3:12b       # 12B
	gemma3:27b       # 27B
	openthinker:32b  # dereict from deepseek-r1
	olmo2:13b        # AI2 fully open no tools
	mistral-small3.1:24b-instruct-q4_K_M
	mistral-small3.1                  # tool and vision 128Kb
	mistral-small3.1:latest           # claims beats gemma3
	mistral-small3.1:24b              # can run on 32GB Mac
	cogito:14b                        # Deep Cogito tool too
	cogito:32b                        # Deep Cogito tool too
	cogito:14b-v1-preview-qwen-q4_K_M # finetuned qwen
	qwen3:14b
	qwen3:32b
	deepcoder        #  Together AI and Agentica
	deepcoder:latest # finetuned deepseek-r1-distilled-qwen
	deepcoder:14b
	qwen3:30b
	phi4                   # Microsoft Jan 7 2025
	phi4:latest            # synthetic, filtered 9.1GB
	phi4:14b               # 16K context length only
	llama3.2-vision        # should run in open-webui
	llama3.2-vision:latest # should run in open-webui
	llama3.2-vision:11b    # vision works now
	deepseek-r1:70b        # disitlled lllama
	cogito:70b             # 128K context
	tulu3:70b              # tulu3 is not much better than llama3 and takes speace
	llama3.2-vision:90b    # vision works now
	llama3.3               # same perforamnce as llama 3.1 405B
	llama3.3:latest        # 128K context
	llama3.3:70b           # 128K context
	aravhawk/llama4:latest
	aravhawk/llama4               # llama 4 scout
	command-a                     # 111b parameters
	command-a:latest              # tools
	command-a:111b                # open weights 23 languages
	command-a:111b-03-2025-q4_K_M # 256K token context
	qwen3:235b
	tulu3                    # AI2 instruction following
	tulu3:latest             # full open source data, code, recipes
	tulu3:8b                 # 128 K content has 70B brother
	llama-guard3             # safety classification
	llama-guard3:latest      # safety classification
	llama-guard3:8b          # safety of prompts
	bespoke-minicheck        # Fact check 7B q4_K_M UT Austin
	bespoke-minicheck:latest # Fact check 7B q4_K_M
	bespoke-minicheck:7b     # Fact check 7B q4_K_M
	gemma3:1b
	deepcoder:1.5b # Agentica and Together AI
	phi4-reasoning:14b
	phi4-reasoning:plus
	llama3.2                    # Meta 3.2-3B Q4 128 context
	llama3.2:latest             # Meta 3.2-3B Q4 128 context
	llama3.2:3b                 # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:3b-instruct-q4_K_M # Meta 3.2-3B Q4 128 context 2GB
	llama3.2:1b                 # Meta 1B 128K context
	llama3.2:1b-instruct-q8_0   # Meta 1B 128K context
	# GGUF models are too big
	granite3.2 # 2b vision model
	granite3.2:latest
	granite3.2:2b # reasoning model messages += []{role: control, content: thinking}]
	granite3.2:2b-instruct-q4_K_M
	hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-abliterated-GGUF
	granite3.2:latest
	granite3.2:8b
	granite3.2:8b-instruct-q4_K_M
	hf.co/LatitudeGames/Wayfarer-Large-70B-Llama-3.3-GGUF # Role play oriented
	hf.co/bartowski/Qwen2-VL-72B-Instruct-GGUF:Q4_K_M
	command-r7b                   # command-r7b is the default
	command-r7b:latest            # latest tool calling
	command-r7b:7b                # 7B
	command-r7b:7b-12-2024-q4_K_M # Dec 2024
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
	sailor2:8b                          # qwen  tuned for se asian languages
	sailor2:8b-chat-q4_K_M              # qwen  tuned for se asian languages
	snowflake-arctic-embed2             # new embeddings
	snowflake-arctic-embed2:latest      # new embeddings
	snowflake-arctic-embed2:568m-l-fp16 # new embeddings
	snowflake-arctic-embed2:568m        # new embeddings
	aya-expanse:32b                     # cohere model 128k content
	aya-expanse:32b-q4_K_M              # cohere model 128k content
	mixtral:8x7b                        # mistral moe (deprecated)
	athene-v2                           # nexusflow based on qwen2.5
	athene-v2:latest                    # code, math, log extraction
	athene-v2:72b                       # code, math, log extraction
	athene-v2:72b-q4_K_M                # code, math, log extraction
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
	nemotron-mini:4b                  # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	nemotron-mini:latest              # nVidia ropeplay, Q&A and function calling 4b-instruct-q4_K-M
	minicpm-v                         # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:latest                  # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:8b                      # mLLM visual too, ocr v2.6 ModelBest CN
	minicpm-v:8b-2.6-q4_0             # mLLM visual too, ocr v2.6 ModelBest CN
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
	mistral-nemo:12b       # 128k context 12b-instruct-2407-q4_0
	shieldgemma:27b        # safety of text prompts
	shieldgemma:27b-q4_K_M # safety of text prompts
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
	bge-large                              # embedding model from BAAI
	bge-large:335m                         # embedding model from BAA
	bge-large:335m-en-v1.5-fp16            # embedding model from BAA
	qwq                                    # like o1
	qwq:latest                             # like o1
	dolphin3                               # llama3.1 8B tuned
	dolphin3:latest                        # no tool calling
	dolphin3:8b                            # llama3.1 8B tuned
	dolphin3:8b-llama3.1-q4_K_M            # llama3.1 8B tuned
	mistral-small                          # this is now the 2503 model
	mistral-small:latest                   # now the 2501 model
	mistral-small:24b-instruct-2501-q4_K_M # the latest model
	r1-1776
	r1-1776                            # perplexity r1 model on latest data
	r1-1776:latest                     # perplexity r1 model on latest data
	r1-1776:70b-distill-llama-q4_K_M   # perplexity r1 model on latest data
	r1-1776:70b                        # perplexity r1 model on latest data
	smollm2                            # open source
	smollm2:latest                     # open source
	smollm2:135m-instruct-q4_K_M       # 135m is small
	smollm2:1.7b                       # large is smarll
	smollm2:1.7b-instruct-q4_K_M       # large is smarll
	granite3-guardian                  # IBM prompt risk
	granite3-guardian:latest           # IBM prompt risk
	granite3-guardian:2b               #  prompt guard
	granite3-guardian:2b-q*_0          #  prompt guard
	granite3-guardian:8b               #  prompt guard
	granite3-guardian:8b-q5_K_M        #  prompt guard ibm
	shieldgemma                        # google safety policies
	shieldgemma:latest                 # google safety policies
	shieldgemma:9b                     # safety of text prompts
	shieldgemma:9b-q4_K_M              # safety of text prompts
	smallthinker:3b                    # long sequence encourage CoT
	smallthinker:3b-preview-q8_0       # open dataset
	smallthinker                       # Fine tuned Qwen2.5-b-instruct
	smallthinker:latest                # qwq used to generate 8K synthetic
	marco-o1                           # Alibab open large reasoning
	marco-o1:latest                    # Alibab open large reasoning
	marco-o1:7b                        # 7b
	marco-o1:7b-q4_K_M                 # q4_K_M
	opencoder                          # completely open source
	opencoder:latest                   # completely open source
	opencoder:1.5b                     #  english and chinse
	opencoder:1.5b-instruct-q4_K_M     #  english and chinse
	qwq:32b-q4_K_M                     # this is the standard not the preview model
	qwq:32b-preview-q4_K_M             # Alibaba advanced reasoning
	qwen2.5:0.5b                       # 128K context Alibaba 2024-09-16 7b
	qwen2.5:1.5b                       # 128K context Alibaba 2024-09-16 7b
	qwen2.5:3b                         # 128K context Alibaba 2024-09-16 7b
	qwen2.5:3b-instruct-q4_K_M         # 128K context Alibaba 2024-09-16 7b
	qwen2.5                            # the larger Alibab models
	qwen2.5:latest                     # 128K context Alibaba 2024-09-16 7b
	qwen2.5:7b                         # 128K context Alibaba 2024-09-16 7b
	qwen2.5:14b                        # 128K context Alibaba 2024-09-16 7b
	qwen2.5-coder:0.5b                 # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b-instruct        # 128K Tuned for coding 7B
	qwen2.5-coder:0.5b-instruct-q8_0   # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b                 # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct        # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct        # 128K Tuned for coding 7B
	qwen2.5-coder:1.5b-instruct-q4_K_M # 128K Tuned for coding 7B
	qwen2.5-coder:7b                   # 128K Tuned for coding 7B
	qwen2.5-coder:latest               # 128K Tuned for coding 7B
	qwen2.5-coder:7b-instruct          # 128K Tuned for coding 7B
	qwen2.5-coder:7b-instruct-q4_K_M   # 128K Tuned for coding 7B
	qwen2.5-coder:14b-instruct-q4_K_M  # 128K Tuned for coding 7B
	qwen2.5-coder:32b-instruct-q4_K_M  # 128K Tuned for coding 7B
	falcon3:10b-instruct-q4_K_M        # 7B parameters
	phi3.5                             # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:latest                      # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	phi3.5:3.8b-mini-instruct-q4_0     # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	gemma2                             # Google 9B Q4 5.4GB 8K context
	gemma2:latest                      # Google 9B Q4 5.4GB 8K context
	gemma2:9b-instruct-q4_0            # Google 9B Q4 5.4GB 8K context
	gemma2:2b                          # Google 9B Q4 5.4GB 8K context
	gemma2:2b-instruct-q4_0            # Google 9B Q4 5.4GB 8K context
	gemma2:27b-instruct-q4_0           # old but only Google model
)
# legacy models for comparison with modern ones
MODEL_OLD+=(
	qwq:32b # Alibaba advanced reasoning
	mistral-small:24b
	qwen2.5:14b       # 128K context Alibaba 2024-09-16 7b
	qwen2.5:32b       # 128K context Alibaba 2024-09-16 7b
	qwen2.5:72b       # 128K context Alibaba 2024-09-16 7b
	qwen2.5-coder:14b # 128K Tuned for coding 7B
	qwen2.5-coder:32b # 128K Tuned for coding 7B
	falcon3:10b       # 7B parameters
	phi3              # the original
	phi3.5:3.8b       # Microsoft 3.8B-instruct-q4_0 beaten by llama3.2?
	# early 2024 models
	llama2:7b           # original llama2
	llama2:13b          # 13b
	gemma2:9b           # Google 9B Q4 5.4GB 8K context
	gemma2:27b          # old but only Google model
	orca-mini:3b        # Microsoft Research
	falcon:7b           # abu dahbi TII
	mistral:7b          # v0.3 of original Mistral
	starcoder:1b        # another fined tuned model
	yi:6b               # yi 1.5
	deepseek-coder:6.7b # first deepseek
	orca2:7b            # Microsoft
	phi:2.7b            # phi-2
	qwen:7b             ## Qwen 1.5
	minicpm-v:8b
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
	# this case no longer works?
	if ((MEMORY >= 8)); then
		INCLUDE_XSMALL=true
		if ((MEMORY >= 16)); then
			INCLUDE_SMALL=true
			if ((MEMORY >= 32)); then
				INCLUDE_MEDIUM=true
				if ((MEMORY >= 64)); then
					INCLUDE_LARGE=true
					if ((MEMORY >= 128)); then
						INCLUDE_XLARGE=true
						if ((MEMORY >= 256)); then
							INCLUDE_XLARGE=true
						fi
					fi
				fi
			fi
		fi
	fi
	log_verbose "automatic sets INCLUDE_MEDIUM=$INCLUDE_MEDIUM INCLUDE_LARGE=$INCLUDE_LARGE INCLUDE_SMALL=$INCLUDE_SMALL INCLUDE_XSMALL=$INCLUDE_XSMALL"
fi

# tests are ordered so that the smallest models are added first to getopts
# as many models as possible in
MODEL_LIST=("${MODEL[@]}")
if $INCLUDE_XSMALL; then
	log_verbose "Include extra small models"
	MODEL_LIST+=("${MODEL_XSMALL[@]}")
	MODEL_MLX+=("${MODEL_MLX_XSMALL[@]}")
fi
if $INCLUDE_SMALL; then
	log_verbose "Include small models"
	MODEL_LIST+=("${MODEL_SMALL[@]}")
	MODEL_MLX+=("${MODEL_MLX_SMALL[@]}")
fi
if $INCLUDE_MEDIUM; then
	log_verbose "Include medium models"
	MODEL_LIST+=("${MODEL_MEDIUM[@]}")
	MODEL_MLX+=("${MODEL_MLX_MEDIUM[@]}")
fi
if $INCLUDE_LARGE; then
	log_verbose "Include large models"
	MODEL_LIST+=("${MODEL_LARGE[@]}")
	MODEL_MLX+=("${MODEL_MLX_LARGE[@]}")
fi
if $INCLUDE_XLARGE; then
	log_verbose "Include extra large models"
	MODEL_LIST+=("${MODEL_XLARGE[@]}")
	MODEL_MLX+=("${MODEL_MLX_XLARGE[@]}")
fi
if $INCLUDE_MEGA; then
	log_verbose "Include extra large models"
	MODEL_LIST+=("${MODEL_MEGA[@]}")
	MODEL_MLX+=("${MODEL_MLX_MEGA[@]}")
fi

# now install speciality models
if $INCLUDE_GGUF; then
	log_verbose "Include HF GGUF models"
	MODEL_LIST+=("${MODEL_GGUF[@]}")
fi
if $INCLUDE_TOOL; then
	log_verbose "Include old models"
	MODEL_LIST+=("${MODEL_TOOL[@]}")
fi
if $INCLUDE_VISION; then
	log_verbose "Include old models"
	MODEL_LIST+=("${MODEL_VISION[@]}")
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

	for model in "$@"; do
		# if you want to pull but not enough room skip it unless forced
		log_verbose "$action model $model"
		if [[ $action == rm ]]; then
			if ! ollama ls "$model" | tail -n +2 | grep -q "^${model}[[:space:]]"; then
				log_verbose "$model already removed"
				continue
			fi
		elif [[ $action == pull ]]; then
			log_verbose "pull: is there enough disk"
			DISK_USED="$(util_disk_used)"
			log_verbose "ollama_action: FORCE=$FORCE action=$action DISK_USED=$DISK_USED DISK_MAX=$DISK_MAX"
			if $DRYRUN || [[ $action == pull ]] && ((DISK_USED > DISK_MAX)) && ! $FORCE; then
				log_verbose "dry run or cannot pull $model $DISK_USED% used at most $DISK_MAX% allowed"
				continue
			fi
			log_verbose "pull: will the model and desired content fit into memory"
			MEMORY="${MEMORY:-$(util_gpu_memory)}"
			log_verbose "MEMORY=$MEMORY MEMORY_RESERVED=$MEMORY_RESERVED"
			# bash is integer only math so use bc
			MEMORY_AVAILABLE=$(bc <<<"$MEMORY * (1 - $MEMORY_RESERVED)")
			log_verbose "Looking for $model in the MODEL_MEM table if it fits in $MEMORY_AVAILABLE GB"
			for item in "${!MODEL_MEM[@]}"; do
				# log_verbose "looking for $item is a substring of $model"
				# is item a substring of model
				if [[ $model =~ $item ]]; then
					model_mem="${MODEL_MEM[$item]}"
					break
				fi
			done
			log_verbose "model_mem=$model_mem"
			model_context="${MODEL_CONTEXT[default]}"
			for item in "${!MODEL_CONTEXT[@]}"; do
				if [[ $model =~ $item ]]; then
					model_context="${MODEL_CONTEXT[$item]}"
					break
				fi
			done
			log_verbose "model_context=$model_context"
			model_context_mem="${MODEL_CONTEXT_MEM[default]}"
			for item in "${!MODEL_CONTEXT_MEM[@]}"; do
				if [[ model =~ $item ]]; then
					model_context_mem="${MODEL_CONTEXT_MEM[$item]}"
					break
				fi
			done
			log_verbose "model_context_mem=$model_context_mem"
			# model context use is per 32K tokens
			mem_needed=$(bc <<<"$model_mem + $model_context * $model_context_mem / 32")
			log_verbose "mem_needed=$mem_needed MEMORY_AVAILABLE=$MEMORY_AVAILABLE"
			if [[ $(bc -l <<<"$mem_needed > $MEMORY_AVAILABLE") == 1 ]]; then
				log_verbose "$model not enough memory for context $mem_needed > $MEMORY_AVAILABLE"
				continue
			fi
		fi
		if ! ollama "$action" "$model"; then
			log_warning "failed $?"
		fi
	done
}

if [[ -v OLLAMA_MODELS ]]; then
	log_verbose "Changing default storage of models to $OLLAMA_MODELS"
	if ! config_mark; then
		config_add <<-EOF
			if [ -z "\$OLLAMA_MODELS" ]; then export OLLAMA_MODELS=\"$OLLAMA_MODELS\"; fi
			if [ -z "\${OLLAMA_API_BASE" ]; then export OLLAMA_API_BASE=\"$OLLAMA_API_BASE\"; fi
		EOF
	fi
fi

if ! pgrep ollama >/dev/null; then
	log_warning "ollama not running"
else
	log_verbose "testing to remove obsolete models (Remove_OBSOLETE=$REMOVE_OBSOLETE_AND_OLD)"
	if $REMOVE_OBSOLETE_AND_OLD; then
		log_verbose "Removing deprecated models ${MODEL_REMOVE[*]}"
		ollama_action rm "${MODEL_REMOVE[@]}" "${MODEL_GGUF_REMOVE[@]}"
		if ! $DRYRUN && $INCLUDE_OLD; then
			ollama_action rm "${MODEL_OLD[@]}"
		fi
		if ! $DRYRUN && $REMOVE_OBSOLETE_AND_OLD; then
			log_verbose "Manually remove ${MODEL_MLX_REMOVE[*]}"
			huggingface-cli delete-cache
		fi
	fi

	log_verbose "$ACTION on ${MODEL_LIST[*]}"
	ollama_action "$ACTION" "${MODEL_LIST[@]}"

fi

if in_os mac && $INCLUDE_MLX; then
	log_verbose "Include HF MLX models"
	if ! $DRYRUN && ($FORCE || ((DISK_USED > DISK_MAX))); then
		huggingface-cli download "${MODEL_MLX[@]}"
	fi
fi

log_verbose "installing ollama environment variables to $WS_DIR/git/src/.envrc"
if ! config_mark "$WS_DIR/git/src/.envrc"; then
	config_add "$WS_DIR/git/src/.envrc" <<-EOF
		[[ -v OLLAMA_KV_CACHE_TYPE ]] || export OLLAMA_KV_CACHE_TYPE=q4_0
		[[ -v OLLAMA_FLASH_ATTENTION ]] || export OLLAMA_FLASH_ATTENTION=1
		[[ -v OLLAMA_CONTEXT_LENGTH ]] || export OLLAMA_CONTEXT_LENGTH=131072
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
	log_verbose "Show local models and sizes"
	log_verbose "Ollama models:"
	for size in GB MB; do
		ollama ls | grep "$size" | sort -nruk 3
	done
	log_verbose "Huggingface cache models"
	huggingface-cli scan-cache | tail -n +3 | sort -unk 3

	if [[ -d $EXO_HOME ]]; then
		log_verbose "Exo MLX models"
		du -sh "${EXO_HOME:-"$HOME/.cache/exo/downloads"}"/* | sort -n
	fi
fi
