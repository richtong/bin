#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Install Terraform and Packer
##
## Including AWS and GGloud providers
## https://learn.hashicorp.com/terraform/getting-started/install.html
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
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Terraform
			    usage: $SCRIPTNAME [ flags ]
			                -h help
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
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1090,SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-util.sh lib-install.sh lib-config.sh

package_install terraform packer

#if ! terraform -install-autocomplete; then
#    log_verbose autocomplete already installed
#fi
# note that completions are exported to subshells so they can all be in profile
# note command completions are bash idea not .profile
# so goes into .bash_profile for macos and .bashrc for ubuntu
if ! config_mark "$(config_profile_for_bash)"; then
	config_add "$(config_profile_for_bash)" <<-'EOF'
		command -v terraform >/dev/null && complete -C "$(brew --prefix)/terraform" terraform
	EOF
fi

log_verbose "source $(config_profile_for_bash) to install autocomplete"
