#!/usr/bin/env bash
##
## install Atom
## https://nearsoft.com/blog/how-to-install-packages-in-atom/
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
ADDITIONAL="${ADDITIONAL:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdva" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Atom and associated packages to make it vim like
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -a all additional packages (default: $ADDITIONAL)
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
	a)
		ADDITIONAL=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh

if ! in_os mac; then
	log_exit "mac only"
fi

log_verbose using brew to install on Mac 1Password and the CLI
if ! cask_install atom; then
	log_error 1 "Could not install atom"
fi

# https://github.com/t9md/atom-vim-mode-plus#installation
# https://hackernoon.com/setting-up-a-python-development-environment-in-atom-466d7f48e297
# https://atom.io/packages/linter-flake8
# https://pythonhow.com/using-atom-as-a-python-editor/
# https://www.pythonmania.net/en/2017/02/27/recommended-atom-packages/
# https://atom.io/packages/docblock-python
# https://medium.com/issuehunt/20-atom-plug-ins-for-python-development-d6b10f8fa33e
APM=(
	vim-mode-plus
	linter
	linter-ui-default
	linter-flake8
	atom-ide-ui
	ide-python
)
apm install "${APM[@]}"

ADDITIONAL_APM=(
	minimap python-autopep8 highlight-selected pigments
	color-picker satom-beautify cript linter-pydocstyle docblock-python
	python-tools build-python
	atom-python-test python-indent python-mrigor python-debugger
	language-python aligner-pythoni python-snippets python-jedi
)

if $ADDITIONAL; then
	apm install "${ADDITIONAL_APM[@]}"
fi

log_verbose "Run your python code with F5 or F6"
