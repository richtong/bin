#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
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
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
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
			    flags: , -h help"
			                       -d $(! $DEBUGGING || echo "no ")debugging
			                       -v $(! $VERBOSE || echo "not ")verbose
			           -g path for go (default: $GOPATH)
			           -r release of go (default: $VERSION)

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
	g)
		GOPATH="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091,SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-config.sh lib-util.sh

PACKAGE+=(
	go
)

if in_os mac; then
	OPTION+=(
		--cross-compile-common
	)
fi

log_verbose "go installation"
# do not quote options in case there are none and you should ignore it.
# shellcheck disable=SC2068
if package_install ${OPTION[@]} "${PACKAGE[@]}"; then
	log_exit "package installed"
fi

mkdir -p "$GOPATH"
if ! config_mark; then
	log_verbose "no config adding"
	# https://golang.org/doc/code.html#GOPATH
	# quotes mean do not interpret
	config_add <<-EOF
		export GOPATH="$GOPATH"
		export PATH="\$PATH:\$(go env GOPATH)/bin"
	EOF
fi

# https://github.com/golang/go/wiki/Ubuntu
# https://launchpad.net/~gophers/+archive/ubuntu/go
if ! snap_install --classic go; then
	log_verbose "Snap install failed trying apt-get"
	apt_install golang
fi

# https://www.digitalocean.com/community/tutorials/how-to-install-go-on-ubuntu-20-04

# no longer work with later Ubuntus
#log_verbose 16.04 has Go v 1.6 so try to install newer
#apt_repository_install ppa:gophers/go
#sudo apt-get update
#sudo apt-get install "golang-$VERSION-go"

log_exit 0 "make sure to source .profile"
