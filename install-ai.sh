#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install desktop AI tools like ChatGPT and Stability Diffusion
##
## https://www.digitaltrends.com/computing/how-to-run-stable-diffusion-on-your-mac/
#
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"

while getopts "hdvr:e:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs AI Tools including Stability Diffusion and ChatGPT
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

# poe - a chatbot aggregator by Quora, allows multiple chats to different bots
# lm-studio -  run different LLMs from Hugging Face locally
# fig - command completion and dotfile manager (still trying it)
# diffusionbee - Stability diffusion on Mac
# shell-gpt - Runs chats from cli including running shell commands
# vincelwt-chatgpt - ChatGPT in menubar
# gpt4all - lm-studio local runner
if in_os mac; then
	PACKAGE+=(

		diffusionbee
		vincelwt-chatgpt
		lm-studio
		poe

	)

	PIP_PACKAGE+=(

		shell-gpt

	)

	# Install Stabiliity Diffusion with DiffusionBee"
	# Download Chat GPT in menubar
	# Use brew install instead of
	#ARCH=x86
	#if mac_is_arm; then
	#ARCH=arm64
	#fi
	#download_url_open "https://github.com/vincelwt/chatgpt-mac/releases/download/v0.0.5/ChatGPT-0.0.5-$ARCH.dmg"
	package_install "${PACKAGE[@]}"
	log_verbose "Pip install only in current environment rerun in other venvs"
	pip_install --upgrade "${PIP_PACKAGE[@]}"
	log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc"

	download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

fi
