#!/usr/bin/env bash
##
## install Go
## http://www.golangbootcamp.com/book/get_setup
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
GOPATH="${GOPATH:-"$HOME/go"}"
VERSION="${VERSION:-"1.10"}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvg:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Go
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -g path for go (default: $GOPATH)
			           -r release of go (default: $VERSION)

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
	g)
		GOPATH="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh lib-util.sh

if in_os mac; then
	log_verbose git install on MacOS
	package_install --cross-compile-common go
	if ! config_mark "$HOME/.bash_profile"; then
		log_verbose no config adding
		mkdir -p "$GOPATH"
		# https://golang.org/doc/code.html#GOPATH
		# quotes mean do not interpret
		config_add <<-EOF
			export GOPATH="$GOPATH"
			export PATH="\$PATH:\$(go env GOPATH)/bin"
		EOF
	fi
	log_exit 0 "make sure to source .bash_profile"
fi

# https://github.com/golang/go/wiki/Ubuntu
if [[ $OSTYPE =~ linux ]]; then
	log_verbose 16.04 has Go v 1.6 so try to install newer
	repository_install ppa:gophers/archive
	sudo apt-get update
	sudo apt-get install "golang-$VERSION-go"
fi
