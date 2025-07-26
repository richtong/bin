#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
# Runs Qwen code
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

CHINA="${CHINA:-false}"
MODELSCOPE="${MODELSCOPE:-false}" # for China, 2000 inferences pere day
OPENROUTER="${OPENROUTER:-false}"
FREE="${FREE:-true}"
FREE_TAG="${FREE_TAG:-:free}"
INTERNATIONAL="${INTERNATIONAL:-true}"

OPTIND=1
while getopts "hdvcmofi-" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Run Qwen code with different providers base on region
			usage: $SCRIPTNAME [ flags ] -- [ claude options ]]
			flags:
				-h help
				-d $($DEBUGGING && echo "no ")debugging
				-v $($VERBOSE && echo "not ")verbose
				-c $($CHINA && echo "no ")Alibaba China
				-m $($MODELSCOPE && echo "no ")Modelscope
				-i $($INTERNATIONAL && echo "no ")International Alibaba DashScope
				-o $($OPENROUTER && echo "no ")Open Router
				-f $($FREE && echo "not ")free on Open Router

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
	c)
		CHINA="$($CHINA && echo false || echo true)"
		;;
	m)
		MODELSCOPE="$($MODELSCOPE && echo false || echo true)"
		;;
	o)
		OPENROUTER="$($OPENROUTER && echo false || echo true)"
		;;
	f)
		FREE="$($FREE && echo false || echo true)"
		if [[ -n $FREE_TAG ]]; then FREE_TAG=""; else FREE_TAG=":free"; fi
		;;
	i)
		INTERNATIONAL="$($INTERNATIONAL && echo false || echo true)"
		;;
	-)
		# the rest of options so pass along
		shift
		break
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

export OPENAI_API_KEY OPENAI_BASE_URL OPENAI_MODEL
if $CHINA; then
	# https://www.youtube.com/watch?v=EkNfythQNRg
	OPENAI_API_KEY="https://dashscope-aliyuncs.com/compatible-mode/v1"

elif $MODELSCOPE; then
	# https://x.com/zhouwenmeng/status/1947866747668775407
	OPENAI_API_KEY="$MODELSCOPE_API_KEY"
	OPENAI_BASE_URL="https://api.inference.modelscope.cn/v1"
	OPENAI_MODEL="${OPENAI_MODEL:-Qwen/Qwen3/Code-480B-A35B-Instruct}"

elif $OPENROUTER; then
	log_warning "Open Router error with API Connection Error"
	OPENAI_API_KEY="$OPENROUTER_API_KEY"
	OPENAI_BASE_URL="https://api.openrouter.ai/v1"
	OPENAI_MODEL="qwen/qwen3-coder$FREE_TAG"

# the default should be last so if other flags are set it is not run
elif $INTERNATIONAL; then
	OPENAI_BASE_URL="https://dashscope-intl.aliyuncs.com/compatible-mode/v1"
	OPENAI_API_KEY="$DASHSCOPE_API_KEY"
	OPENAI_MODEL="${OPENAI_MODEL:-qwen3-coder-plus}"

fi

log_verbose "OPENAI_BASE_URL=$OPENAI_BASE_URL OPENAI_MODEL=$OPENAI_MODEL OPENAI_API_KEY=$OPENAI_API_KEY"
qwen "$@"
