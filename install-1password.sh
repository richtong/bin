#!/usr/bin/env bash
##
## install 1Password
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
## ##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
VERSION="${VERSION:-7}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password

			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING || echo "no ")debugging
				   -v $($VERBOSE || echo "not ")verbose
				   -r version number (default: $VERSION)
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
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

# just source if we are running in a mountable drive
if [[ $SCRIPT_DIR =~ /Volumes ]]; then
	# shellcheck disable=SC1091
	source lib-git.sh lib-mac.sh lib-install.sh lib-util.sh
else
	source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh
fi

if ! in_os mac; then
	log_verbose git install
	# obsoleted by official 1passworld cli
	# https://app-updates.agilebits.com/product_history/CLI
	## https://www.npmjs.com/package/onepass-cli for npm package
	# git_install_or_update 1pass georgebrock
	log_verbose insteall 1Password X for Chrome to use it
	log_exit "Only manual installation supported see https://support.1password.com/command-line-getting-started/"
fi

if [[ -n $(find /Applications -maxdepth 1 -name "1Password*" -print -quit) ]]; then
	log_verbose 1Password for Mac already installed
	exit
fi

log_verbose using brew to install on Mac 1Password and the CLI
if cask_install 1password 1password-cli; then
	log_exit 1password already installed
fi

log_verbose brew cask install failed trying to cure the package
# download_url_open "https://d13itkw33a7sus.cloudfront.net/dist/1P/mac4/1Password-6.0.2.zip"
# more general location
# usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
# Have to increment the OPM number as versions increase
log_verbose "installed 1Password Version $VERSION"
download_url_open "https://app-updates.agilebits.com/download/OPM$VERSION" "1Password.pkg"
