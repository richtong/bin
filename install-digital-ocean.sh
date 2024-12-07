#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
# Install digital ocean tools
#
## @author Rich Tong
## @returns 0 on success
#
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"

OPTIND=1
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Digital Ocean tools
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
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
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh

PACKAGE+=(
	doctl
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

# https://docs.digitalocean.com/reference/doctl/how-to/install/
doctl serverless install

# https://github.com/digitalocean/doctl?tab=readme-ov-file#enabling-shell-auto-completion
log_verbose "if in MacOS, then completion installed automatically"
if ! in_os mac; then
	if ! config_mark "$(config_profile_for_bash)"; then
		config_add "$(config_profile_for_bash)" <<-EOF
			        # Added by install-digitalocean.sh on Thu Dec  8 23:06:08 PST 2022
			        # shellcheck disable=SC1090
			        if command -v doctl >/dev/null; then source <(doctl completion bash); fi
		EOF
	fi
fi
