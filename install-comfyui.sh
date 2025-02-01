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

DIRECT_DOWNLOAD="${DIRECT_DOWNLOAD:-true}"
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
	-g $($DIRECT_DOWNLOAD && echo "echo direct " || echo "moved ") file download
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
		DIRECT_DOWNLOAD="$($DIRECT_DOWNLOAD && echo false || echo true)"
		export DIRECT_DOWNLOAD
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
if $DIRECT_DOWNLOAD; then
	declare -A HF_REPO
	HF_REPO+=(
		["hunyuan-video-t2v-720p-bf16.gguf"]="calcuis/hunyuan-gguf"
		["hunyuan-video-t2v-720p-q8_0.gguf"]="calcuis/hunyuan-gguf"
		["hunyuan-video-t2v-720p-q4_0.gguf"]="calcuis/hunyuan-gguf"
		["clip_l.safetensors"]="calcuis/hunyuan-gguf"
		["llava_llama3_fp8_scaled.safetensors"]="calcuis/hunyuan-gguf"
		["hunyuan_video_vae_bf16.safetensors"]="calcuis/hunyuan-gguf"
		["workflow-hunyuan-gguf.json"]="calcuis/hunyuan-gguf"
		["workflow-hunyuan-gguf.json"]="calcuis/hunyuan-gguf"
		["janus-pro-1b"]="deepseek-ai/janus-pro-1b"
		["janus-pro-7b"]="deepseek-ai/janus-pro-7b"
	)

	# to download a single file
	declare -A HF_DEST
	HF_DEST+=(
		# ["hunyuan-video-t2v-720p-q4_k_m.gguf"]=models/unet # good tradeoff 4-bit doesn't seem to work
		["hunyuan-video-t2v-720p-bf16.gguf"]=models/unet # the original floating point 16-bit
		["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet # good tradeoff 8-bit
		["hunyuan-video-t2v-720p-q4_0.gguf"]=models/unet # good tradeoff 4-bit
		["clip_l.safetensors"]=models/clip
		["llava_llama3_fp8_scaled.safetensors"]=models/clip
		["hunyuan_video_vae_bf16.safetensors"]=/models/vae
		["workflow-hunyuan-gguf.json"]=user/default/workflows
		["workflow-hunyuan-gguf.json"]=user/default/workflows
		["janus-pro-1b"]="models/janus-pro-1b"
		["janus-pro-7b"]="models/janus-pro-7b"
	)

	# do not download a file but leave blank for whole directory
	declare -A HF_WHOLE_REPO
	HF_WHOLE_REPO+=(
		["janus-pro-1b"]=true
		["janus-pro-7b"]=true
	)

	for path in "${!HF_REPO[@]}"; do
		if ! $DRY_RUN; then
			# do not quote the HF_DEST and HF_DIR references it will pick up
			# which everyone is available

			dest="$path"
			if [[ -v HF_WHOLE_REPO[$path] ]]; then
				# download whole repo no need for file path
				# at the source
				dest=""
			fi
			#shellcheck disable=SC2086
			huggingface-cli download "${HF_REPO[$path]}" $dest \
				--local-dir "$COMFYUI_PATH/${HF_DEST[$path]}"
		fi
	done
	log_exit "HuggingFace files pulled"

	# https://comfyui-wiki.com/en/tutorial/advanced/deepseek-janus-pro-workflow
	download_url "https://comfyui-wiki.com/en/tutorial/advanced/deepseek-janus-pro-workflow" "$COMFYUI_PATH/workflows"
	log_verbose "In Nodes manager download CY-Chenyue's ComfyUI-Janus-Pro"
fi

# https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/
log_verbose "Loading models that need to moved to final location"
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
