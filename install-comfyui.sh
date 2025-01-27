#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## Install ComfyUI and models
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

OPTIND=1
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs ComfyUI
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
				   -f $($FORCE && echo "do not ")force install even $SCRIPTNAME exists

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

declare -A HUNYUAN_MODEL_TYPE
HUNYUAN_MODEL_TYPE+=(
	["hunyuan_video_t2v_720p_bf16.safetensors"]=diffusion_models
	["clip_l.safetensors"]=clip
	["llava_llama3_fp8_scaled.safetensors"]=clip
	["hunyuan_video_vae_bf16.safetensors"]=vae
)

REPO="Comfy-Org/HunyuanVideo_repackaged"
COMFYUI_PATH="${COMFYUI_PATH:-"$HOME/Documents/ComfyUI/"}"

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

huggingface-cli download calcuis/hunyuan-gguf clip_l.safetensors --local-dir .
