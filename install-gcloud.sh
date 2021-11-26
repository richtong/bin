#!/usr/bin/env bash
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
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
PACKAGES="${PACKAGES:-" beta "}"
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
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
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
	cask_install google-cloud-sdk

	log_verbose "checking for gcloud in $(config_profile_shell)"
	if ! config_mark "$(config_profile_shell)"; then
		log_verbose "installing into $(config_profile_shell)"
		config_add "$(config_profile_shell)" <<-'EOF'
			source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
			source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
		EOF
		log_warning "now source the changes to $(config_profile_shell)"
	fi

elif in_wsl && [[ ! -e $INSTALL_DIR/google-cloud-sdk ]]; then
	# https://cloud.google.com/sdk/docs/downloads-interactive#linux-mac
	log_verbose "enter the installation directory ~/.local/bin is a good choice"
	download_url "https://sdk.cloud.google.com" "$WS_DIR/cache/install-google-cloud-sdk.sh"
	bash "$WS_DIR/cache/install-google-cloud-sdk.sh" --disable-prompts --install-dir="$INSTALL_DIR"
	if ! config_mark "$(config_shell_profile)"; then
		config_add "$(config_shell_profile)" <<-EOF
			# The next line updates PATH for the Google Cloud SDK.
			if [ -f '$INSTALL_DIR/google-cloud-sdk/path.bash.inc' ]; then . '$INSTALL_DIR/google-cloud-sdk/path.bash.inc'; fi

			# The next line enables shell command completion for gcloud.
			if [ -f 'INSTALL_DIR/google-cloud-sdk/completion.bash.inc' ]; then . '$INSTALL_DIR/google-cloud-sdk/completion.bash.inc'; fi
		EOF
	fi

elif in_os linux; then
	# https://tecadmin.net/how-to-install-google-cloud-sdk-on-ubuntu-20-04/#:~:text=How%20To%20Install%20Google%20Cloud%20SDK%20on%20Ubuntu,comamnd%20line%20reference%20to%20start%20working%20with%20it.
	snap_install google-cloud-sdk
fi

source_profile
hash -r
log_verbose install additional packages "$PACKAGES" "$@"

# all packages cannot contain spaces
# shellcheck disable=SC2086
gcloud components install --quiet $PACKAGES "$@"

# https://stackoverflow.com/questions/42379685/can-i-automate-google-cloud-sdk-gcloud-init-interactive-command
if [[ $(gcloud config configurations list | wc -l) -lt 2 ]]; then
	log_verbose no configuration exists so init
	gcloud init
fi

if gcloud auth list |& grep "No credentialed accounts"; then
	gcloud auth login
	gcloud config set project "$PROJECT"
fi
