#!/usr/bin/env bash
##
## Installs the developer version of Zotero by default
##
# https://www.zotero.org/support/dev_builds
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
STABLE="${STABLE:-false}"
MAC_URL="${MAC_URL:-"https://www.zotero.org/download/standalone/dl?platform=mac&channel=beta"}"
LINUX_URL="${LINUX_URL:-"https://www.zotero.org/download/standalone/dl?platform=linux-x86_64&channel=beta"}"
ZOTFILE_URL="${ZOTFILE_URL:-"https://github.com/jlegewie/zotfile/releases/download/v5.0.16/zotfile-5.0.16-fx.xpi"}"
while getopts "hdvs" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Zotero (and optionally the Beta)
			    usage: $SCRIPTNAME [ flags ]
				flags: -d debug (not functional use bashdb), -v verbose, -h help"
					   -s install the stable version only no beta (default: $STABLE)
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
	s)
		STABLE=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

log_verbose "Install Zotero stable build"
package_install zotero

log_verbose "Install Zotero Beta"
if in_os mac; then
	# https://www.zotero.org/support/kb/safari_compatibility
	log_verbose "Zotero Beta auto installs Safari extension but you need manually enable"
	download_url_open "$MAC_URL" "Zotero-beta.dmg"
else
	download_url_open "$LINUX_URL" "Zotero-Beta"
fi

log_verbose "Install Zotfile plugin to allow sync with Google Drive"
log_verbose "Installing version specific $ZOTFILE_URL"
log_verbose "Start Zotero and go to Tools>Add-ons>Tools>Install ADd-on From File"
log_verbose "The file will be in $WS_DIR/cache"
download_url "$ZOTFILE_URL"
