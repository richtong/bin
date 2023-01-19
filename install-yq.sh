#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install yq and command completion
## https://mikefarah.gitbook.io/yq
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
VERSION="${VERSION:-7}"
DEBUGGING="${DEBUGGING:-false}"
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help"
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
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-config.sh lib-util.sh

if ! in_os mac; then
	log_exit "mac only"
fi

log_verbose "installing yq"
package_install yq
hash -r

# needs goes to .bash_profile if macos, .bashrc otherwise do not need with brew
# install
#if ! config_mark "$(config_profile_for_bash)"; then
#    log_verbose "installing command completion"
#    config_add "$(config_profile_for_bash)" <<-'EOF'
#        # shellcheck disable=SC1090
#        if command -v yq >/dev/null; then source <(yq shell-completion bash); fi
#    EOF
#fi
