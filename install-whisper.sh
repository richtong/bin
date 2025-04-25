#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## Install Whsiper cli and models
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
MODEL_CACHE="$HOME/.cache/whisper"

OPTIND=1
while getopts "hdvgnm:fc:" opt; do
	case "$opt" in
	h)
		cat <<EOF
Installs Speech to Text

$SCRIPTNAME [ flags ]
flags:
	-h help
	-d $($DEBUGGING && echo "no ")debugging
	-v $($VERBOSE && echo "not ")verbose
	-g $($DOWNLOAD && echo "echo direct " || echo "moved ") file download
	-n $($DRY_RUN && echo "no ")dry run
	-m Maximum disk to use (default: $DISK_MAX%)
	-f $($FORCE && echo "no ")force even $DISK_MAX% used
	-c Model cache directory (default: $MODEL_CACHE)

Running speech to text, first convert to wav
	ffmpeg -i _sample.mp4 sample.wav
	whisper-cli -m ggml-base-q8_0.bin --translaste -osrt --print-colors --print-special sample.wav

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
	c)
		MODEL_CACHE="$OPTARG"
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

brew install whisper-cli ffmpeg

# ["hunyuan-video-t2v-720p-q8_0.gguf"]=models/unet   # quarter precision
if ! $DOWNLOAD; then
	log_exit "No downloads"
fi

# https://github.com/ggml-org/whisper.cpp/blob/master/models/download-ggml-model.sh
# https://huggingface.co/ggerganov/whisper.cpp/tree/main
# diarisation of speakers by voice tuned models
# https://huggingface.co/akashmjn/tinydiarize-whisper.cpp
declare -A HF_REPO+=(
	# ["ggml-tiny-q8_0.bin"]="ggerganov/whisper.cpp"
	["ggml-base-q8_0.bin"]="ggerganov/whisper.cpp"
	["ggml-small-q8_0.bin"]="ggerganov/whisper.cpp"
	["ggml-small.en-tdrz.bin"]="akashmjn/tinydiarize-whisper.cpp"
	# ["ggml-medium-q8_0.bin"]="ggerganov/whisper.cpp"
	["ggml-large-v3-turbo-q8_0.bin"]="ggerganov/whisper.cpp"
	# ["ggml-large-v3.bin"]="ggerganov/whisper.cpp"
)

for model in "${!HF_REPO[@]}"; do
	# do not quote the HF_DEST and HF_DIR references it will pick up
	# which everyone is available
	DISK_USED="$(util_disk_used)"
	if ((DISK_USED > DISK_MAX)) && ! $FORCE; then
		log_verbose "disk too full not downloading"
		continue
	fi
	log_verbose "huggingface-cli download ${HF_REPO[$model]} $model --local-dir $MODEL_CACHE"
	if $DRY_RUN; then
		continue
	fi
	# note huggingface-cli is resumable and caches so we don't have to check if
	# the file exists
	#shellcheck disable=SC2086
	huggingface-cli download "${HF_REPO[$model]}" $model --local-dir "$MODEL_CACHE"
done
