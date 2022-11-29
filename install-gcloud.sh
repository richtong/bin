#!/usr/bin/env bash
# vi:set ts=4 sw=4 noet:
##
## Install Google Cloud SDK and major components
## So that at the end you are ready to deploy against GCloud
## https://cloud.google.com/sdk/gcloud/reference/components/install
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

VERSION="${VERSION:-7}"
DEBUGGING="${DEBUGGING:-false}"
# beta now installed by default at least on Ubuntu
#PACKAGES="${PACKAGES:-" beta "}"
PACKAGES="${PACKAGES:-""}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
INSTALL_DIR="${INSTALL_DIR:-"$HOME/.local/bin"}"
PROJECT="${PROJECT:-netdrones}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Google Cloud and components
			    usage: $SCRIPTNAME [ flags ] additional_components (default: $PACKAGES)
			    flags: -d debug, -v verbose, -h help"
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
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-config.sh

if in_os mac; then
	log_verbose install google cloud sdk
	package_install google-cloud-sdk

	if ! config_mark "$(config_profile_for_bash)"; then
		log_verbose "installing into $(config_profile_for_bash)"
		config_add <<-'EOF'
			if [ -r "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc" ]; then
				source \
			    "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc";
			fi
			# shellcheck disable=SC1091
			if [ -r "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc" ]; then
				source \
			    "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc";
			fi
		EOF
	fi

elif in_wsl && [[ ! -e $INSTALL_DIR/google-cloud-sdk ]]; then
	# https://cloud.google.com/sdk/docs/downloads-interactive#linux-mac
	log_verbose "enter the installation directory ~/.local/bin is a good choice"
	download_url "https://sdk.cloud.google.com" "install-google-cloud-sdk.sh"
	bash "$WS_DIR/cache/install-google-cloud-sdk.sh" --disable-prompts --install-dir="$INSTALL_DIR"
	if ! config_mark "$(config_shell_profile)"; then
		config_add "$(config_shell_profile)" <<-EOF
			# The next line updates PATH for the Google Cloud SDK.
			if [ -f '$INSTALL_DIR/google-cloud-sdk/path.bash.inc' ]; then . '$INSTALL_DIR/google-cloud-sdk/path.bash.inc'; fi

			# The next line enables shell command completion for gcloud.
			if [ -f '$INSTALL_DIR/google-cloud-sdk/completion.bash.inc' ]; then . '$INSTALL_DIR/google-cloud-sdk/completion.bash.inc'; fi
		EOF
		log_verbose "Make sure we can see the new commands"
		if [ -f "$INSTALL_DIR/google-cloud-sdk/path.bash.inc" ]; then
			#shellcheck disable=SC1091,SC1090
			. "$INSTALL_DIR/google-cloud-sdk/path.bash.inc"
		fi
	fi

elif in_os linux; then
	# https://snapcraft.io/install/google-cloud-sdk/ubuntu
	# installs but cannot access components
	# snap_install --classic google-cloud-sdk
	# must install from repo instead
	log_verbose "Linux GCloud install"
	package_install apt-transport-https ca-certificates gnupg
	APT="/etc/apt/sources.list.d/google-cloud-sdk.list"
	GPG="/usr/share/keyrings/cloud.google.gpg"
	PACKAGE="https://packages.cloud.google.com/apt"
	if ! grep -q "$PACKAGE" "$APT"; then
		log_verbose "no package found in $APT"
		echo "deb [signed-by=$GPG] $PACKAGE cloud-sdk main" |
			sudo tee -a "$APT"
	fi
	# apt-key deprecated
	# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
	if [[ ! -e $GPG ]]; then
		curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo tee "$GPG" >/dev/null
	fi
	sudo apt-get -y update
	# note we cannot use package_install here since snap will be tried first
	# and this does not have the right version of the google-cloud-sdk
	apt_install google-cloud-sdk
fi

hash -r
log_verbose install additional packages "$PACKAGES" "$@"

# Ubuntu has beta already
if in_os mac; then
	PACKAGES+=" beta "
fi
if [[ -n $PACKAGES ]]; then
	# shellcheck disable=SC2086
	gcloud components install --quiet $PACKAGES "$@"
fi

# https://stackoverflow.com/questions/42379685/can-i-automate-google-cloud-sdk-gcloud-init-interactive-command
if [[ $(gcloud config configurations list | wc -l) -lt 2 ]]; then
	log_verbose no configuration exists so init
	gcloud init
fi

if gcloud auth list |& grep "No credentialed accounts"; then
	gcloud auth login
	gcloud config set project "$PROJECT"
fi

log_verbose "Turn off analytics reporting"
gcloud config set disable_usage_reporting false
