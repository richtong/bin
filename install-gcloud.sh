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
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
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
    esac
done
shift $((OPTIND-1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-config.sh


if ! in_os mac
then
    log_exit "Not tested beyond MacOS"
fi
log_verbose install google cloud sdk
cask_install google-cloud-sdk

log_verbose install additional packages "$PACKAGES" "$@"


# all packages cannot contain spaces
# shellcheck disable=SC2086
gcloud components install $PACKAGES "$@"

PROFILE="${PROFILE:-"$HOME/.bashrc"}"
log_verbose "installing google-cloud-sdk completions into $PROFILE""
if ! config_mark "$PROFILE"
then
    config_add "$PROFILE" <<-EOF
if [[ -e /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc ]]
then
  source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"
fi
EOF
fi

# https://stackoverflow.com/questions/42379685/can-i-automate-google-cloud-sdk-gcloud-init-interactive-command
if [[ $(gcloud config configurations list | wc -l ) < 2 ]]
then
    log_verbose no configuration exists so init
    gcloud init
fi
