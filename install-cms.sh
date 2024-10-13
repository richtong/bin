#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install website content management editing and blogging tools
## @author Rich Tong
## @returns 0 on success
#
# https://chezmoi.io/
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
			Installs Site editing and blogging tools
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
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

if in_os mac; then

	log_verbose "Mac install"
fi

PACKAGE+=(
	wordpresscom        # standalone blog edit
	wordpresscom-studio # offline development for wordpress
	publii              # git-backed cms visual editor
	wp-cli              # wordpress command line
	wp-cli-completion   # command completions
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"
