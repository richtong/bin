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

DOWNLOAD="${DOWNLOAD:-true}"
DRY_RUN="${DRY_RUN:-false}"
FORCE="${FORCE:-false}"
DISK_MAX="${DISK_MAX:-80}"
COMFYUI_PATH="${COMFYUI_PATH:-"$HOME/Documents/ComfyUI"}"

OPTIND=1
while getopts "hdvgnm:f" opt; do
	case "$opt" in
	h)
		cat <<EOF
Installs ComfyUI
usage: $SCRIPTNAME [ flags ]
flags:
	-h help
	-d $($DEBUGGING && echo "no ")debugging
	-v $($VERBOSE && echo "not ")verbose
	-g $($DOWNLOAD && echo "echo direct " || echo "moved ") file download
	-n $($DRY_RUN && echo "no ")dry run
	-m Maximum disk to use (default: $DISK_MAX%)
	-f $($FORCE && echo "no ")force even $DISK_MAX% used
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
		DOWNLOAD="$($DOWNLOAD && echo false || echo true)"
		export DOWNLOAD
		;;
	n)
		DRY_RUN="$($DRY_RUN && echo false || echo true)"
		;;
	m)
		DISK_MAX="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
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

log_verbose "Install Alpha version of ComfyUI Desktop"
if in_os mac; then
	# https://comfyorg.notion.site/ComfyUI-Desktop-User-Guide-1146d73d365080a49058e8d629772f0a#1486d73d3650800089f3fca8e5c94203
	# download_url_open "https://download.comfy.org/mac/dmg/arm64"
	brew install comfyui
elif in_os windows; then
	download_url_open "https://download.comfy.org/windows/nsis/x64"
else
	log_exit "no Linux version"
fi

# ["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet   # quarter precision
if ! $DOWNLOAD; then
	log_exit "No downloads"
fi

declare -A HF_REPO+=(
	# these models are not gguf and not split so you can use for all variants
	["clip_l.safetensors"]="calcuis/hunyuan-gguf"
	["llava_llama3_fp8_scaled.safetensors"]="calcuis/hunyuan-gguf"
	["hunyuan_video_vae_bf16.safetensors"]="calcuis/hunyuan-gguf"
	#
	# the gguf version of hunyuan text to video
	["workflow-hunyuan-gguf.json"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-bf16.gguf"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-q8_0.gguf"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-q4_0.gguf"]="calcuis/hunyuan-gguf"

	["janus-pro-1b"]="deepseek-ai/janus-pro-1b"
	["janus-pro-7b"]="deepseek-ai/janus-pro-7b"

)

# to download a single file
declare -A HF_DEST+=(
	# common for gguf and for bf16 hunyaun video
	["clip_l.safetensors"]=models/clip
	["llava_llama3_fp8_scaled.safetensors"]=models/clip
	["hunyuan_video_vae_bf16.safetensors"]=/models/vae

	#  use the comfy ones instead
	["workflow-hunyuan-gguf.json"]=user/default/workflows
	# ["hunyuan-video-t2v-720p-q4_k_m.gguf"]=models/unet # quantized doesn't
	["hunyuan-video-t2v-720p-bf16.gguf"]=models/unet             # gguf version
	["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet             # good tradeoff 8-bit
	["hunyuan-video-t2v-720p-q4_0.gguf"]=models/unet             # haven't tested
	["hunyuan-video-t2v-720p-bf16.gguf"]=models/diffusion_models # the original floating point 16-bit

	["janus-pro-1b"]="models/janus-pro-1b"
	["janus-pro-7b"]="models/janus-pro-7b"

)

# do not download a file but an entire directory
declare -A HF_WHOLE_REPO+=(
	["janus-pro-1b"]=true
	["janus-pro-7b"]=true
)

declare -A HF_SPLIT_REPO+=(
	# Already copied in the above but need to be in ./text_encoders
	["clip_l.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	["llava_llama3_fp8_scaled.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"

	# hunyuan text to video

	# hunyuan image to video models
	["llava_llama3_vision.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# v1 model
	["hunyuan_video_t2v_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# v2 model concat (more true to original image)
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"

	["umt5_xxl_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan_2.1_vae.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"

	["clip_vision_h.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
)

declare -A HF_SPLIT_SRC+=(
	["clip_l.safetensors"]=split_files/text_encoders
	["llava_llama3_fp8_scaled.safetensors"]="split_files/text_encoders"
	["hunyuan_video_vae_bf16.safetensors"]=split_files/vae

	["llava_llama3_vision.safetensors"]="split_files/clip_vision"
	["hunyuan_video_t2v_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]=split_files/diffusion_models

	# alibaba wan2.1
	["umt5_xxl_fp16.safetensors"]="split_files/text_encoders"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="split_files/text_encoders"
	["wan_2.1_vae.safetensors"]="split_files/vae"
	["clip_vision_h.safetensors"]="split_files/clip_vision"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="split_files/diffusion_models"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="split_files/diffusion_models"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="split_files/diffusion_models"

)

# note that
declare -A HF_SPLIT_DEST+=(
	["clip_l.safetensors"]=models/clip
	["llava_llama3_fp8_scaled.safetensors"]=models/clip
	["hunyuan_video_vae_bf16.safetensors"]=models/vae
	["hunyuan_video_t2v_720p_bf16.safetensors"]=models/diffusion_models

	["llava_llama3_vision.safetensors"]="models/clip_vision"
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]=models/diffusion_models
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]=models/diffusion_models

	["umt5_xxl_fp16.safetensors"]="models/text_encoders"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="models/text_encoders"
	["wan_2.1_vae.safetensors"]="models/vae"
	["clip_vision_h.safetensors"]="models/clip_vision"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="models/diffusion_models"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="models/diffusion_models"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="models/diffusion_models"
)

# given a download url, show where it should go
declare -A DIRECT_DEST+=(
	["https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_text_to_video.json"]=workflows
	["https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_text_to_video.json"]=workflows

	["https://comfyui-wiki.com/en/tutorial/advanced/deepseek-janus-pro-workflow"]=workflows

	# For comfyui checkpoints
	["https://comfyui-wiki.com/en/tutorial/advanced/flux1-comfyui-guide-workflow-and-examples#:~:text=FP8%20Checkpoint%20ComfyUI-,workflow,-example"]=workflows
	["https://comfyui-wiki.com/en/tutorial/advanced/flux1-comfyui-guide-workflow-and-examples#:~:text=Download%20Flux-,Schnell,-FP8%20Checkpoint%20ComfyUI"]=workflows
	["https://huggingface.co/Comfy-Org/flux1-dev/blob/main/flux1-dev-fp8.safetensors"]=models/checkpoints
	["https://huggingface.co/Comfy-Org/flux1-schnell/blob/main/flux1-schnell-fp8.safetensors"]=models/checkpoints
)

for path in "${!HF_REPO[@]}"; do
	# do not quote the HF_DEST and HF_DIR references it will pick up
	# which everyone is available
	dest="$path"
	if [[ -v HF_WHOLE_REPO[$path] ]]; then
		# download whole repo no need for file path
		# at the source
		dest=""
	fi

	DISK_USED="$(util_disk_used)"
	if ((DISK_USED > DISK_MAX)) && ! $FORCE; then
		log_verbose "disk too full not downloading"
		continue
	fi
	log_verbose "huggingface-cli download ${HF_REPO[$path]} $dest --local-dir $COMFYUI_PATH/${HF_DEST[$path]}"
	if $DRY_RUN; then
		continue
	fi

	# note huggingface-cli is resumable and caches so we don't have to check if
	# the file exists
	#shellcheck disable=SC2086
	huggingface-cli download "${HF_REPO[$path]}" $dest \
		--local-dir "$COMFYUI_PATH/${HF_DEST[$path]}"
done

# note that huggingface-cli download will actually create an
# exact copy of the download path
# so it will create the directoyr splitfiles/<type>/
for model in "${!HF_SPLIT_REPO[@]}"; do
	DISK_USED="$(util_disk_used)"
	if ((DISK_USED > DISK_MAX)) && ! $FORCE; then
		log_verbose "disk too full not downloading"
		continue
	fi
	log_verbose "checking $model"
	src="${HF_SPLIT_SRC[$model]}/$model"
	dest_dir="${HF_SPLIT_DEST[$model]}"
	dest="$dest_dir/$model"
	log_verbose "$src -> $dest"

	if [[ -e "$COMFYUI_PATH/$dest" ]]; then
		log_verbose "$COMFYUI_PATH/$dest exists not overwriting"
		continue
	fi
	log_verbose "copy from $src to $dest"
	log_verbose "huggingface-cli download ${HF_SPLIT_REPO[$model]} $src --local-dir $COMFYUI_PATH"
	if $DRY_RUN; then
		continue
	fi
	huggingface-cli download "${HF_SPLIT_REPO[$model]}" \
		"$src" --local-dir "$COMFYUI_PATH"
	log_verbose "since it creates split files, need to move them to the right spot"
	log_verbose "ln -s $COMFYUI_PATH/$src $COMFYUI_PATH/$dest"
	mkdir -p "$COMFYUI_PATH/$dest_dir"
	ln -s "$COMFYUI_PATH/$src" "$COMFYUI_PATH/$dest_dir"
done

# https://comfyui-wiki.com/en/tutorial/advanced/deepseek-janus-pro-workflow
for url in "${!DIRECT_DEST[@]}"; do
	dest="$COMFYUI_PATH/${DIRECT_DEST[$url]}"
	log_verbose "download_url $url $dest"
	if [[ -e $dest ]]; then
		log_verbose "$dest exists not overwriting"
	fi
	download_url "$url" "$COMFYUI_PATH/${DIRECT_DEST[$url]}"
done
