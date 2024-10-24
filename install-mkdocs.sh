#!/usr/bin/env bash
## vi: se noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
#
## Install Python related pieces
## As of June 2022 only the stable version of Homebrew Python
## If you need to use a non stable version, then you
## they are not installed keg-only so you need to add
## $(brew --prefix)/opt/python@$VERSION/libexec/bin to your path
## to get the right symlinks
##
##
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

VERBOSE="${VERBOSE:-false}"
DEBUGGING="${DEBUGGING:-false}"

OPTIND=1
# which user is the source of secrets
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF


			Install mkdocs, mkdocs-material another documentation plugins
			even if conda is not activated. So you need to manage the conda version at all times.

			usage: $SCRIPTNAME [flags...]
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
		echo "no -$opt flag" >&2
		;;
	esac
done
# shellcheck disable=SC1091
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh lib-install.sh
shift $((OPTIND - 1))
# log_verbose "PATH=$PATH"

# mkdocs - documents made easy
PACKAGE+=(
	mkdocs
)

# shellcheck disable=SC2086
package_install "${PACKAGE[@]}"

# Only install pip packages if not in homebrew as
# raw pip in homebrew does not allow it

# mkdocs-material - Add material design to documentation
# mkdocs-material[imaging] - for social support
# mkdocstrings - Add docstrings from python code into mkdocs
# mkdocs-minify-plugin - Minify HTML output
# pymdown-extensions - Add markdown extensions
# mkdocs-charts-plugin - Add vega-lite chart support
# mkdocs-jupyter - Add jupyter notebooks to mkdocs
# mkdocs-git-revision-date-localized-plugin - Add date using material
# mkdocs-enumerate-headings-plugin - automatically add heading numbers
# markdown-exec[ansi] -  can run the code blocks in the doc site!@#!
PYTHON_PACKAGE+=(

	mkdocstrings
	mkdocs-material
	"mkdocs-material[imaging]"
	mkdocs-minify-plugin
	mkdocs-redirects
	mkdocs-monorepo-plugin
	mkdocs-awesome-pages-plugin
	pymdown-extensions
	mkdocs-charts-plugin
	mkdocs-jupyter
	mkdocs-git-revision-date-localized-plugin
	mkdocs-enumerate-headings-plugin
	"markdown-exec[ansi]"
	mkdocs-git-commiters-plugin-2

)

if [[ -n ${PYTHON_PACKAGE[*]} ]]; then
	log_verbose "installing python packages ${PYTHON_PACKAGE[*]} in the base system and upgrade dependencies"
	pip_install --upgrade "${PYTHON_PACKAGE[@]}"
fi

log_verbose "User Site packages are in $(brew --prefix)/lib/python*/site-packages"
