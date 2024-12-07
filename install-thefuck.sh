#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install thefuck command line completion
## ##@author Rich Tong
##@returns 0 on success
#
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
			Installs The Fuck
			usage: $SCRIPTNAME [ flags ]
			flags:
				   -h help
				   -d $($DEBUGGING && echo "no ")debugging
				   -v $($VERBOSE && echo "not ")verbose
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
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-install.sh lib-config.sh

package_install thefuck

# note the omz plugin thefuck conflicts with sudo and just handles ESC ESC this lets you run
# the correct command by typing fuck
for profile in "$(config_profile_nonexportable_bash)" "$(config_profile_nonexportable_zsh)"; do
	if ! config_mark "$profile"; then
		config_add "$profile" <<-'EOF'
			# shellcheck disable=SC2046
			if command -v thefuck >/dev/null; then eval $(thefuck --alias); fi
		EOF
	fi
done

log_verbose "expects zsh installed by install-zsh.sh"
