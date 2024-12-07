#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install Basic Tex for Latex support
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
			Installs Latex with BasicTex and then install plugins as needed
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

PACKAGE+=(
	basictex
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

# https://tex.stackexchange.com/questions/307483/setting-up-basictex-homebrew
# recommends running path_helper but this does not work it odes add the
# additional library but also masks everything else with /usr/bin and other
# things in the standard /etc/paths.d/ directory.
#log_verbose "Add to the path"
#eval "$(/usr/libexec/path_helper)"
# need to source again since basictex installs tlmgr
# https://pandoc.org/installing.html
if ! config_mark; then
	config_add <<-'EOF'
		# shellcheck disable=SC1090
		echo "$PATH" | grep -q "/Library/TeX/texbin" || PATH="/Library/TeX/texbin:$PATH"
	EOF
fi

#source "$HOME/.profile"
# use the path now
echo "$PATH" | grep -q "/Library/TeX/texbin" || PATH="/Library/TeX/texbin:$PATH"

log_verbose "update tlmgr"
sudo tlmgr update --self

TLMGR_PACKAGE+=(
	latexmk # bibtex cross references
	collection-fontsrecommended
)

log_verbose "Install ${TLMGR_PACKAGE[*]}"
for TL_PACKAGE in "${TLMGR_PACKAGE[@]}"; do
	sudo tlmgr install "$TL_PACKAGE"
done
