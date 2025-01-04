#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
# Convert AI Model in Huggingface to Ollama/llama.cpp GGUF
#
## @author Rich Tong
## @returns 0 on success
#
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"

MODEL_DIR="${MODEL_DIR:-"$WS_DIR/data/models/"}"
QUANTIZATION="${QUANTIZATION:-"Q4_K_M"}"
OPTIND=1
while getopts "hdvfm:q:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Convert Huggingface model to GGUF model
			usage: $SCRIPTNAME [ flags ] [repo/model...
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
				   -f $($FORCE && echo "do not ")force install even $SCRIPTNAME exists
				   -m Model directory (default: $MODEL_DIR)
				   -q Quantization (default: $QUANTIZATION)

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
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	m)
		MODEL_DIR="$OPTARG"
		;;
	q)
		QUANTIZATION="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;

	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

PACKAGE+=(
	huggingface-cli
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

mkdir -p "$MODEL_DIR"

for hf in "$@"; do
	# https://stackoverflow.com/questions/20348097/bash-extract-string-before-a-colon
	# https://stackoverflow.com/questions/15148796/get-string-after-character
	hf_org="${hf%%/*}"
	hf_model="${hf#*/}"
	log_verbose "download $hf_org/$hf_model"
	huggingface-cli download "$hf_org/$hf_model" --local-dir "$MODEL_DIR/$hf_model" --include "*"
	log_verbose "convert ot fp32 gguf in $MODEL_DIR/$hf_model.gguf"
	docker run --rm -v "$MODEL_DIR/$hf_model":/repo ghcr.io/ggerganov/llama.cpp:full --outtype f32 --outfile "/repo/$hf_model.gguf"
	log_verbose "quantize to $QUANT"
	docker run --rm -v "$MODEL_DIR/$hf_model":/repo ghcr.io/ggerganov/llama.cpp:full --quantize "$QUANTIZATION" \
		"/repo/$hf_model.quantized.gguf" "/repo/$hf_model.$QUANTIZATION.gguf" "$QUANTIZATION"
done
