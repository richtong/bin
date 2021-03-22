#!/bin/bash
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
FRAMES=100
OUTPUT_FORMAT='jpg'

# Parse args
while getopts "hf:o:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Split a video into a set number of frames using ffmpeg
			usage: $SCRIPTNAME [ flags ] [ inputs ]
			flags:
			    -h help
			    -f interval of frame capture (default: $FRAMES)
			    -o output format (default: $OUTPUT_FORMAT)

		EOF
		exit 0
		;;
	f)
		FRAMES="${OPTARG}"
		;;
	o)
		OUTPUT_FORMAT=$OPTARG
		;;

	*)
		echo "no -$opt"
		;;
	esac
done

shift $((OPTIND - 1))

# Split each input video into frames
for fname in "$@"; do
	base="$(cut -d'.' -f1 <<<"$fname")"
	ffmpeg -i "$fname" -vf "select=not(mod(n\, $FRAMES))" -vsync vfr "frames/${base}_%03d.${OUTPUT_FORMAT}"
done
