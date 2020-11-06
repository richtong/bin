#!/usr/bin/env bash
##
## Install rkt
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
RKT_KEY="${RKT_KEY:-"18AD5014C99EF7E3BA5F6CE950BDD3E0FC8A365E"}"
RKT_REL="${RKT_REL:-"1.25.0"}"
RKT_FILE="${RKT_FILE:-"rkt_$RKT_REL-1_amd64.deb"}"
RKT_URL="${RKT_URL:-"https://github.com/coreos/rkt/release/download/v$RKT_REL/$RKT_FILE"}"

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install CoreOS rkt"
		echo "flags: -d debug, -v verbose, -h help"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-util.sh
set -u
shift $((OPTIND - 1))

if command -v rkt; then
	log_verbose rkt already installed
fi

if in_os mac; then
	log_verbose Installing for Mac
	pushd "$WS_DIR/git" >/dev/null
	git_install_or_update "https://github.com/coreos/rkt" rkt
	pushd rkt >/dev/null
	popd
	popd
else
	# note that to make gpg work on Mac http://blog.ghostinthemachines.com/2015/03/01/how-to-use-gpg-command-line/
	# you run `brew install gnupg2`
	log_verbose assumes we are ubuntu so need to wget
	mkdir -p "$WS_DIR/cache"
	cd "$WS_DIR/cache"
	if [[ ! -e $RKT_FILE ]]; then
		gpg --recv-key "$RKT_KEY"
		wget "$RKT_URL"
		wget "$RKT_URL.asc"
		gpg --verfity "$RKT_FILE.asc"
	fi
	sudo dpkg -i "$RKT_FILE"
	cd -
fi

log_verbose testing configuration

if [[ $OSTYPE =~ darwin ]]; then
	RKT=${RKT:-"vagrant ssh -c sudo rkt"}
else
	RKT=${RKT:-"sudo rkt"}
fi

# Give more memory https://www.virtualbox.org/manual/ch08.html#idm3792
vboxmanage modifyvm --memory 4096

# note we do not want double quotes, $RKT should parse as individual arguments
$RKT run --net=host --insecure-options=image docker://nginx
$RKT list
$RKT stop
$RKT rm
$RTK image rm nginx
