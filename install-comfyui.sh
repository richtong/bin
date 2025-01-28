#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## Install ComfyUI and models
## @author Rich Tong
## @returns 0 on success
#

set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"

QUANTIZED_DOWNLOAD="${QUANTIZED_DOWNLOAD:-true}"
DRY_RUN="${DRY_RUN:-false}"

OPTIND=1
while getopts "hdvgn" opt; do
	case "$opt" in
	h)
		cat <<EOF
Installs ComfyUI
usage: $SCRIPTNAME [ flags ]
flags:
	-h help
	-d $($DEBUGGING && echo "no ")debugging
	-v $($VERBOSE && echo "not ")verbose
	-g $($QUANTIZED_DOWNLOAD && echo "quantized GGUF " || echo "Half precision FP16 ") model download
	-n $($DRY_RUN && echo "no ")dry run
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
	g)
		QUANTIZED_DOWNLOAD="$($QUANTIZED_DOWNLOAD && echo false || echo true)"
		export QUANTIZED_DOWNLOAD
		;;
	n)
		DRY_RUN="$($DRY_RUN && echo false || echo true)"
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

# https://comfyorg.notion.site/ComfyUI-Desktop-User-Guide-1146d73d365080a49058e8d629772f0a#1486d73d3650800089f3fca8e5c94203
log_verbose "Install Alpha version of ComfyUI Desktop"
download_url_open "https://download.comfy.org/mac/dmg/arm64"

COMFYUI_PATH="${COMFYUI_PATH:-"$HOME/Documents/ComfyUI"}"

# ["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet   # quarter precision
if $QUANTIZED_DOWNLOAD; then
	HUNYUAN_GGUF_REPO="${HUNYUAN_FULL_REPO:-"calcuis/hunyuan-gguf"}"
	declare -A HUNYUAN_GGUF_PATH
	HUNYUAN_GGUF_PATH+=(
		# ["hunyuan-video-t2v-720p-q4_k_m.gguf"]=models/unet # good tradeoff 4-bit doesn't seem to work
		["hunyuan-video-t2v-720p-bf16.gguf"]=models/unet # the original floating point 16-bit
		["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet # good tradeoff 8-bit
		["hunyuan-video-t2v-720p-q4_0.gguf"]=models/unet # good tradeoff 4-bit
		["clip_l.safetensors"]=models/clip
		["llava_llama3_fp8_scaled.safetensors"]=models/clip
		["hunyuan_video_vae_bf16.safetensors"]=/models/vae
		["workflow-hunyuan-gguf.json"]=user/default/workflows
	)
	for file in "${!HUNYUAN_GGUF_PATH[@]}"; do
		log_verbose "huggingface-cli download $HUNYUAN_GGUF_REPO $file \
				--local-dir $COMFYUI_PATH/${HUNYUAN_GGUF_PATH[$file]}"
		if ! $DRY_RUN; then
			huggingface-cli download "$HUNYUAN_GGUF_REPO" "$file" \
				--local-dir "$COMFYUI_PATH/${HUNYUAN_GGUF_PATH[$file]}"
		fi
	done
	log_exit "GGUF Quantized models pulled"
fi

# https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/
log_verbose "Loading FP16 half precision models"
REPO="Comfy-Org/HunyuanVideo_repackaged"
declare -A HUNYUAN_MODEL_TYPE
HUNYUAN_MODEL_TYPE+=(
	["hunyuan_video_t2v_720p_bf16.safetensors"]=diffusion_models
	["clip_l.safetensors"]=clip
	["llava_llama3_fp8_scaled.safetensors"]=clip
	["hunyuan_video_vae_bf16.safetensors"]=vae
)
# note that huggingface-cli download will actually create an
# exact copy of the download path
# so it will create the directoyr splitfiles/<type>/
for model in "${!HUNYUAN_MODEL_TYPE[@]}"; do
	huggingface-cli download "$REPO" \
		"split_files/${HUNYUAN_MODEL_TYPE[$model]}/$model" \
		--local-dir "$COMFYUI_PATH"
done

log_verbose "since it creates split files, need to move them to the right spot"
mv "$COMFYUI_PATH/split_files/"* "$COMFYUI_PATH/models"
