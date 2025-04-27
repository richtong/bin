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
export FLAGS="${FLAGS:-""}"

MODEL_CACHE="${MODEL_CACHE:-"$HOME/.cache/whisper"}"
MODEL="${MODEL:-"ggml-large-v3-turbo-q8_0.bin"}"
TLDZ_MODEL="${TLDZ_MODEL:-"ggml-small.en-tdrz.bin"}"
TLDZ="${TLDZ:-false}"

OPTIND=1
while getopts "hdvntm:c:" opt; do
	case "$opt" in
	h)
		cat <<EOF

$SCRIPTNAME [ flags ] [files-to-be-transcribed...]
flags:
	-h help
	-d $($DEBUGGING && echo "no ")debugging
	-v $($VERBOSE && echo "not ")verbose
	-m Whisper Transcription Model Maximum disk to use (default: $MODEL)
	-c Model cache directory (default: $MODEL_CACHE)
	-t $($TLDZ && echo "no ")Tiny Diarization model to detect speakers changes

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
	m)
		MODEL="$OPTARG"
		;;
	c)
		MODEL_CACHE="$OPTARG"
		;;
	t)
		TLDZ="$($TLDZ && echo false || echo true)"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh

for file in "$@"; do
	# check if file exists
	if [[ ! -e $file ]]; then
		log_verbose "File $file does not exist"
		continue
	fi

	base="${file%.*}"

	suffix="${file##*.}"
	log_verbose "base=$base suffix=$suffix"
	# check if file is a video or audio file
	if [[ ! $suffix =~ (mp4|mkv|avi|mov|mp3|wav) ]]; then
		log_verbose "File $file is not a video or audio file"
		continue
	fi
	# check if ffmpeg is installed
	if ! command -v ffmpeg &>/dev/null; then
		log_verbose "ffmpeg could not be found, please install it first"
		continue
	fi

	# convert to wav if not already in wav format
	if [[ $suffix != wav ]]; then
		ffmpeg -i "$file" -vn -acodec pcm_s16le -ar 44100 -ac 2 "$base.wav"
	fi

	whisper-cli -m "$MODEL_CACHE/$MODEL" -f "$base.wav" --print-colors
	whisper-cli -m "$MODEL_CACHE/$TLDZ_MODEL" -tdrz -f "$base.wav" --print-colors

done
