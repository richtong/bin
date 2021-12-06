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
source_lib lib-install.sh lib-mac.sh

package_install zotero

if is_mac; then
	# https://www.zotero.org/support/kb/safari_compatibility
	log_verbose "Zotero Beta auto installs Safari extension but you need manually enable"
	download_url_open "$MAC_URL"
else
	download_url_open "$LINUX_URL"
fi
