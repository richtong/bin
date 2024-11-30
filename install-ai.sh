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
# l
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

# https://lobehub.com/blog/5-ollama-web-ui-recommendation

PACKAGE+=(

	# fig - command completion and dotfile manager (bought by Amazon and closed)
	# gpt4all - lm-studio local runner (lm-studio now does this as well nicer us)
	# macgpt - ChatGPT in menubar (pretty useless, deprecated)
	# poe - a chatbot aggregator by Quora, allows multiple chats (not using)
	# shell-gpt - cli including running shell commands (never use deprecated)
	# vincelwt-chatgpt - ChatGPT in menubar (not using)
	# appflowy        # project manager based on ai (don't ever use)
	cursor          # pair programming using VScode, takes over the `code`
	diffusionbee    # diffusionbee - Stability diffusion on Mac
	lm-studio       # lm-studio -  run different LLMs from Hugging Face locally
	mochi-diffusion # mochi-diffusion - Stability diffusion on Mac (haven't used)
	parquet-cli     # command line opening parquet data files
	cursor          # ai code editor that's based on code
	zed             # yet another ai editor
	jan             # grafical front-end for llama.cpp

)

MAS+=(
	6474268307 # Enchanted LLM Mac only selfhosted
)
mas_install "${MAS[@]}"

PYTHON_PACKAGE+=(

	open-interpreter # let's LLMs run code locally
	"open-interpreter[local]"
	"open-interpreter[os]"

)

# Install Stabiliity Diffusion with DiffusionBee"
# Download Chat GPT in menubar
# Use brew install instead of
#ARCH=x86
#if mac_is_arm; then
#ARCH=arZZm64
#fi
#download_url_open "https://github.com/vincelwt/chatgpt-mac/releases/download/v0.0.5/ChatGPT-0.0.5-$ARCH.dmg"
package_install "${PACKAGE[@]}"
log_verbose "Pip install only in current environment rerun in other venvs"
pipx_install "${PYTHON_PACKAGE[@]}"

# log_warning "shell-gpt requires OPENAI_API_KEY to be set or will store in ~/.config/shell_gpt/.sgptrc
log_warning "WEBUI_SECRET_KEY and OPENAI_API_KEY should both be defined before running ideally in a .envrc"
log_verbose "To add Groq to OPen-webui Lower Left > Admin Panel > Settings > Connections > OpenAI API"
log_verbose "Click on + on he right and add URL https://api.groq.com/openai/v1 and your GROQ key"
# https://zohaib.me/extending-openwebui-using-pipelines/
# log_verbose "https://github.com/open-webui/pipelines"
log_verbose "To add Gemini, add functions or pipelines you need to run a docker and add it"
log_verbose 'docker run -d -p 9099:9099 --add-host=host.docker.internal:host-gateway \ '
log_verbose '-v pipelines:/app/pipelines --name pipelines --restart always \ '
log_verbose "ghcr.io/open-webui/pipelines:main"
log_verbose "or fork and submodule add git@githbu.com:open-webui/pipelines"
log_verbose "pip install - requriements.txt && sh .start.sh"

# no need for gp4all
#download_url_open "https://gpt4all.io/installers/gpt4all-installer-darwin.dmg"

log_verbose "install ollama and models"
"$BIN_DIR/install-ollama.sh"
