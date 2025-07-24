#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
# Runs claude with different providers
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

KIMI_K2="${KIMI_K2:-false}"
QWEN3_CODER="${QWEN3_CODER:-false}"

OPTIND=1
while getopts "hdvkq-" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Run Claude code with different providers
			usage: $SCRIPTNAME [ flags ] -- [ claude options ]]
			flags:
				-h help
				-d $($DEBUGGING && echo "no ")debugging
				-v $($VERBOSE && echo "not ")verbose
				-k $($KIMI_K2 && echo "no ")Moonshot Kimi K2
				-q $($QWEN3_CODER && echo "no ")Alibaba Qwen3 Coder

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
	k)
		KIMI_K2="$($KIMI_K2 && echo false || echo true)"
		export KIMI_K2
		;;
	q)
		QWEN3_CODER="$($QWEN3_CODER && echo false || echo true)"
		export QWEN3_CODER
		;;
	-)
		# the rest all claude options so pass along
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

if $KIMI_K2; then
	# https://www.youtube.com/watch?v=EkNfythQNRg
	export ANTHROPIC_BASE_URL="https://api.moonshot.ai/anthropic"
	export ANTHROPIC_AUTH_TOKEN="$MOONSHOT_API_KEY"
	log_warning "if any mcp servers are not function, kimi will fail"

elif $QWEN3_CODER; then
	# https://x.com/zhouwenmeng/status/1947866747668775407
	export ANTHROPIC_BASE_URL="https://dashscope-intl.aliyuncs.com/api/v2/apps/claude-code-proxy"
	export ANTHROPIC_AUTH_TOKEN="$ALIBABA_API_KEY"
fi

claude "$@"
