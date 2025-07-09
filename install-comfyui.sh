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
# note do not use ~/Documents as iCloud Sync works there
COMFYUI_PATH="${COMFYUI_PATH:-"$HOME/ComfyUI"}"
# if you have workflows you want checked in change here
COMFYUI_WORKSPACE="${COMFYUI_WORKSPACE:-"$WS_DIR/git/src/res/tne-comfyui-workflows/workflows"}"
COMFYUI_WORKSPACE_DEST="${COMFYUI_WORKSPACE_DEST:-"$COMFYUI_PATH/user/default/workflows"}"

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

	# https://docs.comfy.org/tutorials/video/cosmos/cosmos-predict2-video2world
	["cosmos_predict2_14B_video2world_720p_16fps.safetensors"]=Comfy-Org/Cosmos_Predict2_repackaged
	["cosmos_predict2_2B_video2world_480p_16fps.safetensors"]=Comfy-Org/Cosmos_Predict2_repackaged
	["oldt5_xxl_fp8_e4m3fn_scaled.safetensors"]=comfyanonymous/cosmos_1.0_text_encoder_and_VAE_ComfyUI
	["wan_2.1_vae.safetensors"]=Comfy-Org/Wan_2.1_ComfyUI_repackaged

	# https://comfyui-wiki.com/en/tutorial/advanced/image/hidream/i1-t2i
	# note fuzzy and not working
	["ae.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	["clip_g_hidream.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	["clip_l_hidream.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI
	["hidream_i1_dev_fp8.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI  # 28 steps and faster
	["hidream_i1_full_fp8.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI # 50 step
	["llama_3.1_8b_instruct_fp8_scaled.safetensors"]=Comfy-Org/HiDream-I1_ComfyUI

	# Alibaba Hunyuan Video GGUF -- old but have experience with it
	["clip_l.safetensors"]="calcuis/hunyuan-gguf"
	["hunyuan_video_vae_bf16.safetensors"]="calcuis/hunyuan-gguf"
	["hunyuan-video-t2v-720p-bf16.gguf"]="calcuis/hunyuan-gguf"
	# ["hunyuan-video-t2v-720p-q4_0.gguf"]="calcuis/hunyuan-gguf"  # this is very slow do not use
	["hunyuan-video-t2v-720p-q8_0.gguf"]="calcuis/hunyuan-gguf"
	["llava_llama3_fp8_scaled.safetensors"]="calcuis/hunyuan-gguf"
	["workflow-hunyuan-gguf.json"]="calcuis/hunyuan-gguf"

	# Alibaba Hunyuan non-GF with BF16
	# Already copied in the above but need to be in ./text_encoders
	# ["clip_l.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# ["hunyuan_video_image_to_video_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged" # v2 model concat (more true to original image)
	# ["hunyuan_video_t2v_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"            # v1 model
	# ["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# ["llava_llama3_fp8_scaled.safetensors"]="Comfy-Org/HunyuanVideo_repackaged"
	# ["llava_llama3_vision.safetensors"]="Comfy-Org/HunyuanVideo_repackaged" # hunyuan image to video models

	# Deepseek Janus Pro
	# ["Janus-Pro-1B"]="deepseek-ai/Janus-Pro-1B"
	# ["Janus-Pro-7B"]="deepseek-ai/Janus-Pro-7B"

	# Alibaba Wan 2.1  # replaced by VACE
	# ["clip_vision_h.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	# ["umt5_xxl_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	# ["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	# ["wan_2.1_vae.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	# ["wan2.1_i2v_480p_14B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	# ["wan2.1_i2v_720p_14B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"
	# ["wan2.1_t2v_1.3B_fp16.safetensors"]="Comfy-Org/Wan_2.1_ComfyUI_repackaged"

	# https://comfyui-wiki.com/en/tutorial/advanced/lumina-image-2
	# ["lumina_2.safetensors"]=Comfy-Org/Lumina_Image_2.0_Repackaged

	# Flux.1-dev retain for compatibility replaced by Kontext but this is not
	# working on Mac
	["flux1-dev-fp8.safetensors"]=Comfy-Org/flux1-dev
	# ["flux1-schnell-fp8.safetensors"]=Comfy-Org/flux1-schnell  # poor quality

)

# needed for split_files
declare -A HF_SRC_PATH+=(

	# Cosmos
	["oldt5_xxl_fp8_e4m3fn_scaled.safetensors"]=text_encoders
	["wan_2.1_vae.safetensors"]=split_files/vae

	# Hidream (not working)
	["ae.safetensors"]=split_files/vae
	["clip_g_hidream.safetensors"]=split_files/text_encoders
	["clip_l_hidream.safetensors"]=split_files/text_encoders
	["hidream_i1_dev_fp8.safetensors"]=split_files/diffusion_models
	["hidream_i1_full_fp8.safetensors"]=split_files/diffusion_models
	["llama_3.1_8b_instruct_fp8_scaled.safetensors"]=split_files/text_encoders

	# alibaba wan2.1
	["clip_vision_h.safetensors"]="split_files/clip_vision"
	["umt5_xxl_fp16.safetensors"]="split_files/text_encoders"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="split_files/text_encoders"
	["wan_2.1_vae.safetensors"]="split_files/vae"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="split_files/diffusion_models"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="split_files/diffusion_models"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="split_files/diffusion_models"

	# Alibaba Hunyuqn
	["clip_l.safetensors"]=split_files/text_encoders
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_t2v_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]=split_files/diffusion_models
	["hunyuan_video_vae_bf16.safetensors"]=split_files/vae
	["llava_llama3_fp8_scaled.safetensors"]="split_files/text_encoders"
	["llava_llama3_vision.safetensors"]="split_files/clip_vision"
	["lumina_2.safetensors"]=all_in_one

)

# to download a single file
declare -A HF_DEST+=(
	# cosmos location
	["cosmos_predict2_14B_video2world_720p_16fps.safetensors"]=Comfy-Org/Cosmos_Predict2_repackaged
	["cosmos_predict2_2B_video2world_480p_16fps.safetensors"]=Comfy-Org/Cosmos_Predict2_repackaged
	["cosmos_predict2_2B_video2world_480p_16fps.safetensors"]=Comfy-Org/Cosmos_Predict2_repackaged

	# Hidream
	["clip_l_hidream.safetensors"]=models/text_encoders
	["clip_g_hidream.safetensors"]=models/text_encoders
	["llama_3.1_8b_instruct_fp8_scaled.safetensors"]=models/text_encoders
	["ae.safetensors"]=models/vae
	["hidream_i1_full_fp8.safetensors"]=models/diffusion_models
	["hidream_i1_dev_fp8.safetensors"]=models/diffusion_models

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
	["clip_vision_h.safetensors"]="models/clip_vision"
	["hunyuan_video_image_to_video_720p_bf16.safetensors"]=models/diffusion_models
	["hunyuan_video_t2v_720p_bf16.safetensors"]=models/diffusion_models
	["hunyuan_video_v2_replace_image_to_video_720p_bf16.safetensors"]=models/diffusion_models
	["hunyuan_video_vae_bf16.safetensors"]=models/vae
	["llava_llama3_fp8_scaled.safetensors"]=models/clip
	["llava_llama3_vision.safetensors"]="models/clip_vision"
	["umt5_xxl_fp16.safetensors"]="models/text_encoders"
	["umt5_xxl_fp8_e4m3fn_scaled.safetensors"]="models/text_encoders"
	["wan_2.1_vae.safetensors"]="models/vae"
	["wan2.1_i2v_480p_14B_fp16.safetensors"]="models/diffusion_models"
	["wan2.1_i2v_720p_14B_fp16.safetensors"]="models/diffusion_models"
	["wan2.1_t2v_1.3B_fp16.safetensors"]="models/diffusion_models"

	# Deepseek Janus
	["Janus-Pro-1B"]="models/Janus-Pro/Janus-Pro-1B"
	["Janus-Pro-7B"]="models/Janus-Pro/Janus-Pro-7B"

	# Lumina 2
	["lumina_2.safetensors"]=models/checkpoints

	# Flux goes into checkpoints
	["flux1-dev-fp8.safetensors"]=models/checkpoints
	["flux1-schnell-fp8.safetensors"]=models/checkpoints
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

	["https://stable-diffusion-art.com/wp-content/uploads/2025/02/lumina-image-2.json"]=workflows

)
declare HF_REMOVE+=(

	# obsolete older than March 2025
	#
	# Alibaba Wan 2.1  # replaced by VACE
	clip_vision_h.safetensors
	umt5_xxl_fp16.safetensors
	umt5_xxl_fp8_e4m3fn_scaled.safetensors
	wan_2.1_vae.safetensors
	wan2.1_i2v_480p_14B_fp16.safetensors
	wan2.1_i2v_720p_14B_fp16.safetensors
	wan2.1_t2v_1.3B_fp16.safetensors

	Janus-Pro-1B
	Janus-Pro-7B
	lumina_2.safetensors
	flux1-schnell-fp8.safetensors

	# too slow
	hunyuan-video-t2v-720p-q4_0.gguf

)

log_exit "deprecated: use drop an image with the workflow in it or Workflow > Template; manually clean ./Comfy"

for item in "${!HF_REMOVE[@]}"; do
	log_verbose "Removing $item at ${HF_DEST[$item]}"
	rm -rf "${HF_DEST[$item]}"
done

for item in "${!HF_REPO[@]}"; do
	# do not quote the HF_DEST and HF_DIR references it will pick up
	# which everyone is availablehttps://comfyui-wiki.com/en/tutorial/advanced/lumina-image-2
	hf_src="$item"
	if [[ -v HF_WHOLE_REPO[$item] ]]; then
		# download whole repo no need for file path
		# at the source
		hf_src=
	fi

	DISK_USED="$(util_disk_used)"
	if ((DISK_USED > DISK_MAX)) && ! $FORCE; then
		log_verbose "disk too full not downloading"
		continue
	fi

	# note huggingface-cli is resumable and caches so we don't have to check if
	# the file exists
	log_verbose "installing item=$item from hf_src=$hf_src"
	if [[ ! -v HF_SRC_PATH[$item] ]]; then
		log_verbose "direct install: hf_repo=${HF_REPO[$item]} hf_src=$hf_src cui=$COMFYUI_PATH local_dest=${HF_DEST[$item]}"
		if ! $DRY_RUN; then
			# if $dest is null, it just cpies the whole repo which we want for
			# whole repo
			#shellcheck disable=SC2086
			huggingface-cli download "${HF_REPO[$item]}" $hf_src --local-dir "$COMFYUI_PATH/${HF_DEST[$item]}"
		fi
	else
		# HR_SRC_PATH[$item] exists so a complex apth
		hf_src="${HF_SRC_PATH[$item]}/$item"
		dest_dir="${HF_DEST[$item]}"
		dest="$dest_dir/$item"

		log_verbose "pathed install: model=$item, hf_repo=${HF_REPO[$item]}, dest=$dest, src=$hf_src, dest_dir=$dest_dir"
		log_verbose "huggingface-cli download ${HF_REPO[$item]} $hf_src --local-dir $COMFYUI_PATH"
		if $DRY_RUN; then
			continue
		fi

		if [[ -e "$COMFYUI_PATH/models/$dest" ]]; then
			log_verbose "$COMFYUI_PATH/models/$dest exists not overwriting"
			continue
		fi
		# if $dest is null, it just cpies the whole repo which we want for
		# whole repo
		#shellcheck disable=SC2086
		huggingface-cli download "${HF_REPO[$item]}" "$hf_src" --local-dir "$COMFYUI_PATH"

		log_verbose "symlink: relative symlink from: $COMFYUI_PATH/$hf_src to:$dest"
		if [[ ! -e $COMFYUI_PATH/$dest ]]; then
			mkdir -p "$(dirname "$COMFYUI_PATH/$dest_dir")"
			pushd "$COMFYUI_PATH/$dest_dir" >/dev/null
			log_verbose ln -s "$(realpath --relative-to=. "$COMFYUI_PATH/$hf_src")" .
			ln -s "$(realpath --relative-to=. "$COMFYUI_PATH/$hf_src")" .
			popd >/dev/null
		fi

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

if [[ -d $COMFYUI_WORKSPACE ]] && [[ ! -e $COMFYUI_WORKSPACE_DEST ]]; then
	log_verbose "Setting default workspace to $COMFYUI_WORKSPACE"
	ln -s "$COMFYUI_WORKSPACE" "$COMFYUI_WORKSPACE_DEST"
fi

log_verbose "To finish Janus Pro Installation, download the Janus Pro Node in ComfyUI Manager"
log_verbose "Get the Hidream I1 Workflow from the ComfyUI Workflow Templates"
