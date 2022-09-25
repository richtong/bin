#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
## Installs the latest ruby
##
## Note travis needs at least 1.9.3 for version 1.8
##
## @author Rich Tong
## @returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

VERSION=${VERSION:-3.0.0}

VERSION=${VERSION:-2.1}
OPTIND=1
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: install ruby
			flags: -r ruby version (default: $VERSION)
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
	r)
		VERSION="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1090,SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
log_verbose "about to source"
source_lib lib-version-compare.sh lib-util.sh lib-config.sh lib-install.sh

set -u

RUBY_PATH="${RUBY_PATH:-"$(brew --prefix)/opt/ruby/bin/"}"
log_verbose "installing ruby"
if brew_install ruby; then
	log_verbose "raw version is $("$RUBY_PATH/ruby" -v)"
	version="$("$RUBY_PATH/ruby" -v | cut -d ' ' -f 2)"
	log_verbose "ruby version $version"
	version="$(echo "$version" | util_semver)"
	log_verbose "ruby version after util_semvar $version"
	if ! config_mark; then
		log_verbose "installing gem bin $version and ruby"
		config_add <<-EOF
			command -v brew >/dev/null && echo \$PATH | grep -q $RUBY_PATH || PATH="\$(brew --prefix):/opt/ruby/bin:\$PATH"
			command -v brew >/dev/null && echo \$PATH | grep -q "\$(brew --prefix)/lib/ruby/gems" || PATH+="\$(brew --prefix)lib/ruby/gem/$version/bin"
		EOF
	fi
	log_exit "brew installed ruby"
fi

# https://www.thoughtco.com/instal-ruby-on-linux-2908370#:~:text=How%20to%20Install%20Ruby%20on%20Linux%201%20Open,exact%2C%20but%20if%20you%20are%20...%20See%20More.
log_verbose "trying ruby-full"
if package_install ruby-full; then
	log_exit "ruby-full installs"
fi

# For travis using 12.04, need different install
# http://stackoverflow.com/questions/4023830/bash-how-compare-two-strings-in-version-format
##install
##@param $1 package name
##@param $2 ppa repository
install() {
	log_verbose "installing $1 from $2"
	sudo apt-get install -y python-software-properties
	sudo add-apt-repository -r -y "$2"
	sudo add-apt-repository -y "$2"
	sudo apt-get update
	sudo apt-get install -y "$1"
}

if ! command -v ruby || verlt "$(ruby -v | cut -d' ' -f 2)" 1.9.3; then
	install "ruby2.1" "ppa:brightbox/ruby-ng"
	sudo apt-get install -y ruby-switch "ruby$VERSION-dev"
	sudo ruby-switch --set ruby "$VERSION"
fi
