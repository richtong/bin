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

if in_os windows; then
	download_url_open "https://download.comfy.org/windows/nsis/x64"
else
	# https://comfyorg.notion.site/ComfyUI-Desktop-User-Guide-1146d73d365080a49058e8d629772f0a#1486d73d3650800089f3fca8e5c94203
	# download_url_open "https://download.comfy.org/mac/dmg/arm64"
	brew install comfyui
fi

# ["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet   # quarter precision
if ! $DOWNLOAD; then
	log_exit "No downloads"
fi

# https://comfyui-wiki.com/en/tutorial/advanced/flux1-comfyui-guide-workflow-and-examples
declare -A HF_REPO+=(
	# Flux.1-dev
	["flux1-dev-fp8.safetensors"]=Comfy-Org/flux1-dev
	["flux1-schnell-fp8.safetensors"]=Comfy-Org/flux1-schnell

	# Alibaba Hunyuan Video GGUF
	["clip_l.safetensors"]="calcuis/hunyuan-gguf"
	["llava_llama3_fp8_scaled.safetensors"]="calcuis/hunyuan-gguf"
	["hunyuan_video_vae_bf16.safetensors"]="calcuis/hunyuan-gguf"
	["workflow-hunyuan-gguf.json"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-bf16.gguf"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-q8_0.gguf"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-q4_0.gguf"]="calcuis/hunyuan-gguf"

	# Alibaba Hunyuan non-GF with BF16
	# Already copied in the above but need to be in ./text_encoders
	["clip_l.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	["llava_llama3_fp8_scaled.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# hunyuan image to video models
	["llava_llama3_vision.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# v1 model
	["hunyuan_video_t2v_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# v2 model concat (more true to original image)
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"

	# Deepseek Janus Pro
	["Janus-Pro-1B"]="deepseek-ai/Janus-Pro-1B"
	["Janus-Pro-7B"]="deepseek-ai/Janus-Pro-7B"

	# Alibaba Wan 2.1
	["umt5_xxl_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan_2.1_vae.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["clip_vision_h.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"

	# https://comfyui-wiki.com/en/tutorial/advanced/lumina-image-2
	["lumina_2.safetensors"]=Comfy-Org/Lumina_Image_2.0_Repackaged

	# https://comfyui-wiki.com/en/tutorial/advanced/image/hidream/i1-t2i
	["clip_l_hidream.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	["clip_g_hidream.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	["llama_3.1_8b_instruct_fp8_scaled.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	["ae.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	# 50 steps high quality and slow
	["hidream_i1_full_fp8.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	# 28 steps and faster
	["hidream_i1_dev_fp8.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI

)

declare -A HF_SRC_PATH+=(
	["clip_l.safetensors"]=split_files/text_encoders
	["llava_llama3_fp8_scaled.safetensors"]="split_files/text_encoders"
	["hunyuan_video_vae_bf16.safetensors"]=split_files/vae
	["llava_llama3_vision.safetensors"]="split_files/clip_vision"
	["hunyuan_video_t2v_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]=split_files/diffusion_models
	["lumina_2.safetensors"]=all_in_one
	# alibaba wan2.1
	["umt5_xxl_fp16.safetensors"]="split_files/text_encoders"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="split_files/text_encoders"
	["wan_2.1_vae.safetensors"]="split_files/vae"
	["clip_vision_h.safetensors"]="split_files/clip_vision"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="split_files/diffusion_models"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="split_files/diffusion_models"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="split_files/diffusion_models"

	["clip_l_hidream.safetensors"]=split_files/text_encoders
	["clip_g_hidream.safetensors"]=split_files/text_encoders
	["llama_3.1_8b_instruct_fp8_scaled.safetensors"]=split_files/text_encoders
	["ae.safetensors"]=split_files/vae
	["hidream_i1_full_fp8.safetensors"]=split_files/diffusion_models
	["hidream_i1_dev_fp8.safetensors"]=split_files/diffusion_models

)

# to download a single file
declare -A HF_DEST+=(
	["flux1-dev-fp8.safetensors"]=models/checkpoints
	["flux1-schnell-fp8.safetensors"]=models/checkpoints

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

	# original hunyuan
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

	["Janus-Pro-1B"]="models/Janus-Pro/Janus-Pro-1B"
	["Janus-Pro-7B"]="models/Janus-Pro/Janus-Pro-7B"

	["lumina_2.safetensors"]=models/checkpoints

	["clip_l_hidream.safetensors"]=models/text_encoders
	["clip_g_hidream.safetensors"]=models/text_encoders
	["llama_3.1_8b_instruct_fp8_scaled.safetensors"]=models/text_encoders
	["ae.safetensors"]=models/vae
	["hidream_i1_full_fp8.safetensors"]=models/diffusion_models
	["hidream_i1_dev_fp8.safetensors"]=models/diffusion_models

)

# do not download a file but an entire directory
declare -A HF_WHOLE_REPO+=(
	["Janus-Pro-1B"]=true
	["Janus-Pro-7B"]=true
)

# given a download url, show where it should go
declare -A DIRECT_DEST+=(
	["https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_text_to_video.json"]=workflows
	["https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_text_to_video.json"]=workflows

	["https://comfyui-wiki.com/en/tutorial/advanced/deepseek-Janus-Pro-workflow"]=workflows

	# For comfyui checkpoints
	["https://comfyui-wiki.com/en/tutorial/advanced/flux1-comfyui-guide-workflow-and-examples#:~:text=FP8%20Checkpoint%20ComfyUI-,workflow,-example"]=workflows
	["https://comfyui-wiki.com/en/tutorial/advanced/flux1-comfyui-guide-workflow-and-examples#:~:text=Download%20Flux-,Schnell,-FP8%20Checkpoint%20ComfyUI"]=workflows

	["https://stable-diffusion-art.com/wp-content/uploads/2025/02/lumina-image-2.json"]=workflows

)

for model in "${!HF_REPO[@]}"; do
	# do not quote the HF_DEST and HF_DIR references it will pick up
	# which everyone is availablehttps://comfyui-wiki.com/en/tutorial/advanced/lumina-image-2
	path="$model"
	if [[ -v HF_WHOLE_REPO[$model] ]]; then
		# download whole repo no need for file path
		# at the source
		path=
	fi

	DISK_USED="$(util_disk_used)"
	if ((DISK_USED > DISK_MAX)) && ! $FORCE; then
		log_verbose "disk too full not downloading"
		continue
	fi

	# note huggingface-cli is resumable and caches so we don't have to check if
	# the file exists
	log_verbose "installing path=$path model=$model"
	log_verbose "dest=${HF_DEST[$model]}"
	if [[ ! -v HF_SRC_PATH[$model] ]]; then
		log_verbose "direct install: huggingface-cli download ${HF_REPO[$model]} $path --local-dir $COMFYUI_PATH/${HF_DEST[$model]}"
		if ! $DRY_RUN; then
			# if $dest is null, it just cpies the whole repo which we want for
			# whole repo
			#shellcheck disable=SC2086
			huggingface-cli download "${HF_REPO[$model]}" $path --local-dir "$COMFYUI_PATH/${HF_DEST[$model]}"
		fi
	else
		# we have a longer path like split_files/models or all_in_one
		src="${HF_SRC_PATH[$model]}/$model"
		dest_dir="${HF_DEST[$model]}"
		dest="$dest_dir/$model"

		log_verbose "pathed install: model=$model, dest=$dest, src=$src, dest_dir=$dest_dir"
		log_verbose "huggingface-cli download ${HF_REPO[$model]} $src --local-dir $COMFYUI_PATH"
		if $DRY_RUN; then
			continue
		fi

		if [[ -e "$COMFYUI_PATH/$dest" ]]; then
			log_verbose "$COMFYUI_PATH/$dest exists not overwriting"
			continue
		fi
		# if $dest is null, it just cpies the whole repo which we want for
		# whole repo
		#shellcheck disable=SC2086
		huggingface-cli download "${HF_REPO[$model]}" "$src" --local-dir "$COMFYUI_PATH"
		log_verbose "creates a path in $COMFYUI_PATH/$src so symlink to right place"
		log_verbose "ln -s $COMFYUI_PATH/$src $COMFYUI_PATH/$dest_dir"
		mkdir -p "$COMFYUI_PATH/$dest_dir"
		ln -s "$COMFYUI_PATH/$src" "$COMFYUI_PATH/$dest_dir"

	fi

done

# https://comfyui-wiki.com/en/tutorial/advanced/deepseek-Janus-Pro-workflow
for url in "${!DIRECT_DEST[@]}"; do
	dest="$COMFYUI_PATH/${DIRECT_DEST[$url]}"
	log_verbose "download_url $url $dest"
	if [[ -e $dest ]]; then
		log_verbose "$dest exists not overwriting"
	fi
	download_url "$url" "$COMFYUI_PATH/${DIRECT_DEST[$url]}"
done

log_verbose "To finish Janus Pro Installation, download the Janus Pro Node in ComfyUI Manager"
log_verbose "Get the Hidream I1 Workflow from the ComfyUI Workflow Templates"
