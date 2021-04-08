#!/usr/bin/env bash
##
## install node and npm on Debian/Ubuntu or Mac OS X
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
# for bashdb
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# July 2020
VERSION="${VERSION:-12}"
BREW="${BREW:-true}"
OPTIND=1
while getopts "hdvr:x" opt; do
	case "$opt" in
	h)
		cat <<EOF
$SCRIPTNAME: Install Node and NPM
    "flags: -d debug, -v verbose, -h help"
	       -r release of node [default: $VERSION]"
           -x set to disable brew (brew is normally $BREW)"
EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	r)
		VERSION="$OPTARG"
		;;
	x)
		BREW=false
		;;
	*)
		log_warning "invalid flag $opt"
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-version-compare.sh lib-util.sh
shift $((OPTIND - 1))

if $BREW; then
	# Now assumes brew is in linux
	# the old way was node 4.0, now using node 6
	# package_install nodejs4 npm 2
	# change from package to brew
	# package_install nodejs6 npm2
	log_verbose install brew
	brew_install node
	log_exit brew complete
fi

if command -v node >/dev/null && vergte "$(node --version)" "v$VERSION"; then
	log_verbose "have node $VERSION or higher no need to install over it"
	exit
fi

# make sure to purge the old installation
package_uninstall nodejs

# regular node install works
# This install node 0.1 and npm 1.1 on ubuntu 14.04 from standard repo
#package_install nodejs nodejs-legacy npm

# To get node 4.x, npm 2.x and node to point to nodejs
# https://github.com/nodesource/distributions#debinstall
# curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
# To get node 6.x with ES6 support and includes node-legacy now
curl -sL "https://deb.nodesource.com/setup_${VERSION}.x" | sudo -E bash -
package_install nodejs

if ! log_assert "[[ $(node -v) =~ ^v$VERSION ]]" "node installed to $VERSION"; then
	exit $?
fi
