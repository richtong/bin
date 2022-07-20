#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install 1Password
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Create a GPG Signature and save the files
			    usage: $SCRIPTNAME [ flags ] gpg_signature
			    flags: -d debug, -v verbose, -h help"
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
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-mac.sh lib-install.sh lib-util.sh

# https://www.techrepublic.com/article/how-to-create-and-export-a-gpg-keypair-on-macos/

GPG_ID=("$(gpg --list-secret-keys | sed -n "/^sec/{n;p}")")
log_verbose "found ids ${GPG_ID[*]}"
GPG_NAME=("$(gpg --list-secret-keys | grep -o "<.*>" | tr -d '<>')")
log_verbose "found ids ${GPG_NAME[*]}"

exit

# https://stackoverflow.com/questions/17403498/iterate-over-two-arrays-simultaneously-in-bash
for i in "${!GPG_ID[@]}"; do
	log_verbose "on gpg identifier number $i identifier ${GPG_ID[i]} name ${GPG_NAME[i]}"
	gpg --export-secret-keys "${GPG_ID[i]}" >"$HOME/.ssh/${GPG_NAME[i]}.gpg"
	gpg --armor --export "${GPG_ID[i]}" >"$HOME/.ssh/${GPG_NAME[i]}.gpg.pub"
done
