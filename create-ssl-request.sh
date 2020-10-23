#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## install self host
##
## Based on the script
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

CLOUD_USER=${CLOUD_USER:-"$USER"}
OPTIND=1
while getopts "hdvw:u:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: flags: -d debug, -h help"
		echo "    -w WS directory"
		echo "    -u User (default: $CLOUD_USER)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	u)
		CLOUD_USER="$OPTARG"
		;;
	*)
		echo "no flag -$opt" >&2
		;;
	esac
done
CLOUD_EMAIL=${CLOUD_EMAIL:-"$CLOUD_USER@surround.io"}

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

# WS_DIR not set until after include.sh is sourced
SSL_BIN=${SSL_BIN:-"$WS_DIR/git/public-keys/ssl"}

set -u

shift $((OPTIND - 1))

if ! command -v xsel; then
	sudo apt-get install -y xsel
fi

if [[ ! -d "$HOME/Private" ]]; then
	"$BIN_DIR/install-ecryptfs.sh"
fi
mkdir -p "${PRIVATE:="$HOME/Private/ssh"}"

PEM=${PEM:-"$PRIVATE/$CLOUD_EMAIL.key.pem"}

git_install_or_update public-keys

"$SSL_BIN/gen-server-ssl-key" "$PEM" | xsel --clipboard

log_warning "passphrase for $PEM in clipboard, please save somewhere safe like 1Password"

CSR=${CSR:-"$PRIVATE/$CLOUD_EMAIL"}
CLOUD_URL=${CLOUD_URL:-"$CLOUD_USER-cloud.alpha.surround.io"}
log_warning reenter the pass phrase from the clipboard now
"$SSL_BIN/gen-server-csr" -k "$PEM" -o "$CSR" "$CLOUD_URL"

log_warning send to administrator your certificate request in "$CSR":
cat "$CSR"

log_warning "when you get it back, place in $PEM"
