#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install GNU utilities
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
# This is for Brew
# https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities
# for m1 macs it is /opt/homebrew and for intel macs it is /usr/local use brew --prefix to make portable
BREW_GNU="${BREW_GNU:-"$(brew --prefix)/opt/coreutils/libexec/gnubin"}"
# https://superuser.com/questions/440288/where-does-macports-install-gnu-sed-when-i-install-coreutils-port
PORT_GNU="${PORT_GNU:-"/opt/local/bin"}"
OPTIND=1
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install GNU Utilities because macOS only has old Berkeley Unix tools
			usage: $SCRIPTNAME [ flags ]
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
				   -f $(! $FORCE || echo "not ")force gcc install over system
				      On Ubuntu this can break many things
		EOF
		exit 0
		;;
	d)
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-config.sh lib-util.sh

shift $((OPTIND - 1))

# http://meng6.net/pages/computing/installing_and_configuring/installing_and_configuring_command-line_utilities/
# Note that gettext is needed as well but not included in the list above
log_verbose installing gnu base packages
package_install coreutils binutils diffutils gawk gnutls gzip screen \
	watch wget gnupg gnupg2 gettext man-db gcc

if $FORCE && [[ ! -e $HOME/.local/bin/gcc ]]; then
	log_warning "link $HOME/.local/bin/gcc to gcc-version but this break Ubuntu"
	mkdir -p "$HOME/.local/bin"
	GCC_WITH_VERSION="$(find "$(brew --prefix)/bin" -name "gcc-[0-9]*" -print -quit)"
	if [[ -v GCC_WITH_VERSION ]]; then
		ln -s "$GCC_WITH_VERSION" "$HOME/.local/bin/gcc"
	fi
fi

# https://stackoverflow.com/questions/30003570/how-to-use-gnu-sed-on-mac-os-x
log_verbose since January 2019, fix --with-default-names by adding paths
package_install findutils gnu-indent gnu-sed gnu-tar gnu-which grep gnu-getopt
log_verbose need to fix gnu-sed first because it is required by the lib-config.sh

# log_verbose installing gnu package needing --with-default-names
# package_install --with-default-names findutils gnu-indent gnu-sed gnu-tar gnu-which grep
if in_os mac; then
	package_install --with-gettext wdiff
else
	package_install wdiff
fi

package_install bash guile gpatch m4 make nano
if ! mac_is_arm; then
	log_verbose "gdb only on Intel Linux or Mac"
	package_install gdb
fi

# installing other utilities like rename
log_verbose util-linux
package_install util-linux

log_verbose bash link
if ! command -v bash | grep -q "$(brew --prefix)/bin"; then
	brew link --overwrite bash
fi

# This is the gui version of emacs
# brew install --cocoa -srgb emacs
# linkapps is deprecated should not need this just connect
# emacs to /Applications
# brew linkapps emacs
package_install emacs

# Note there are non GNU utilities as well

# do not use the prefix less portable and more specific
# https://www.topbug.net/blog/2013/04/14/install-and-use-gnu-command-line-tools-in-mac-os-x/
# PATH+="$(brew --prefix coreutils)/libexec/gnubin"
# https://apple.stackexchange.com/questions/69223/how-to-replace-mac-os-x-utilities-with-gnu-core-utilities
# https://lists.macosforge.org/pipermail/macports-users/2011-June/024582.html
# To get gnu ls so we can use dircolors
log_verbose "adding $BREW_GNU to path for this script and export for called"

log_verbose Make sure gnu sed is used instead of the Mac default permanently

if [[ ! $PATH =~ $BREW_GNU ]]; then
	export PATH="$BREW_GNU:$PATH"
	hash -r
fi

# Also make sure to have a new line before the #Added in case
# other apps like Goodsync do not add one
# Note this assume line_add_or_change appends at bottom so that GNU_PATH goes
# first in the path masking the system utils like ls
# note we use /bin/sh for this since it goes into .profile
if ! config_mark; then
	log_verbose "add paths for utilities"
	# single quote except where we have the $NAME entry
	config_add <<-"EOF"
		        echo "$PATH" | grep -q "$BREW_GNU" || PATH="$BREW_GNU:\$PATH"
		        for NAME in gnu-indent gnu-sed gnu-tar gnu-which grep make findutils; do
		            echo "$PATH" | grep -q "opt/$NAME/libexec/gnubin" ||
		                PATH="$HOMEBREW_PREFIX/opt/$NAME/libexec/gnubin:$PATH"
		        done
		        for NAME in gnu-getopt gettext m4; do
		            echo "$PATH" | grep -q "opt/$NAME/bin" ||
		                PATH="$BREW_PREFIX/opt/$NAME/bin:$PATH"
		        done
				for NAME in man-db; do
					echo "$PATH" | grep -q "opt/$NAME/libexec/bin" ||
						PATH="$BREW_PREFIX/opt/$NAME/libexec/bin:$PATH"
				done
	EOF
fi

log_verbose "make sure to run lib/lib-util.sh/source_profile to get the new paths"
