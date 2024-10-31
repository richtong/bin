#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
export FLAGS="${FLAGS:-""}"

GPG_ORG="${GPG_ORG:-$WS_ORG}"
GPG_USER="${GPG_USER:=$USER}"
GPG_EMAIL="${GPG_EMAIL:=$GPG_USER@$GPG_ORG}"
GPG_NAME="${GPG_NAME:-$GPG_EMAIL}"

while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Create a GPG Signature and save the files
			    usage: $SCRIPTNAME [ flags ] gpg_signature
				flags:
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
				   -f $($FORCE && echo "do not ")force install even $SCRIPTNAME exists
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
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh

PACKAGE+=(
	gpg
	gpg-tui # https://github.com/orhun/gpg-tui
)

package_install "${PACKAGE[@]}"

log_verbose "installing moving gpg keys to .ssh"
# https://www.techrepublic.com/article/how-to-create-and-export-a-gpg-keypair-on-macos/
# https://bmaingret.github.io/blog/2022-02-15-1Password-gpg-git-seamless-commits-signing
GPG_ID=("$(gpg --list-secret-keys | sed -n "/^sec/{n;p}")")
log_verbose "found ids ${GPG_ID[*]}"
GPG_NAME=("$(gpg --list-secret-keys | grep -o "<.*>" | tr -d '<>')")
log_verbose "found ids ${GPG_NAME[*]}"

# https://stackoverflow.com/questions/17403498/iterate-over-two-arrays-simultaneously-in-bash
for i in "${!GPG_ID[@]}"; do
	log_verbose "on gpg identifier number $i identifier ${GPG_ID[i]} name ${GPG_NAME[i]}"
	gpg --export-secret-keys "${GPG_ID[i]}" >"$HOME/.ssh/${GPG_NAME[i]}.gpg"
	gpg --armor --export "${GPG_ID[i]}" >"$HOME/.ssh/${GPG_NAME[i]}.gpg.pub"
done
