#!/usr/bin/env bash
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
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
# need to use trap and not -e so bashdb works
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
ANACONDA="${ANACONDA:-false}"
PIPENV="${PIPENV:-true}"
# If version is set to null then the default python version is used
PYTHON_VERSION="${PYTHON_VERSION:-}"
NEW_PYTHON="${NEW_PYTHON:-@3.10}"
# we normally don't need the oldest version
OLD_PYTHON="${OLD_PYTHON:-@3.8}"
PYENV="${PYENV:-false}"
OPTIND=1
# which user is the source of secrets
while getopts "hdvaeyp:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Install python components

			usage: $SCRIPTNAME [flags...]

			  -h help
			  -v verbose
			  -d single step debugging
			              -a disable anaconda (normally installed)
			              -e disable pipenv (normally installed)
			  -y install pyenv to manage python versions (default: $PYENV)
              -p install python version (default: ${PYTHON_VERSION:-stable})
		EOF

		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	a)
		ANACONDA=false
		;;
	e)
		PIPENV=false
		;;
	y)
		PYENV=true
		;;
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh lib-install.sh
shift $((OPTIND - 1))

#if ! in_os mac; then
#log_exit "Mac only"
#fi

# Kite is Python code completer not used instead use Github copilot
# https://github.com/kiteco/jupyterlab-kite
#kite
PACKAGES+=(
	black
	pydocstyle
)

if [[ -v PYTHON_VERSION ]]; then
    log_verbose "will install $PYTHON_VERSION"
	PACKAGES+=("python$PYTHON_VERSION")
fi

if [[ $PYTHON_VERSION =~ @ ]]; then
    log_warning "Installing a python variant $PYTHON_VERSION"
    log_warning "This is keg-only and requires manually linking"
fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing ${PACKAGES[*]}"
# packages are ok globbed
# shellcheck disable=SC2086
package_install "${PACKAGES[@]}"

# we need it to be python and pip to work and not python3 and pip3 only
# https://docs.brew.sh/Homebrew-and-Python
if ! config_mark; then
	# Use the brew location for python
	config_add <<-EOF
		# shellcheck disable=SC2155
		[[ \$PATH =~ \$HOMEBREW_PREFIX/opt/python$PYTHON_VERSION/libexec/bin ]] || export PATH="\$HOMEBREW_PREFIX/opt/python$PYTHON_VERSION/libexec/bin:$PATH"
	EOF
	log_warning "source $(config_profile) to get the correct python"
fi

# add the correct python if not already there
# you cannot just source it again because this will
# cause the default paths to be put in before this path
#source_profile
export PATH
[[ $PATH =~ $(brew --prefix)/opt/python/libexec/bin ]] || PATH="$(brew --prefix)/opt/python/libexec/bin:$PATH"
hash -r

if $PIPENV; then
	PACKAGES+=(pipenv)
	log_verbose "use pipenv per directory pipenv install"
fi

if $PYENV; then
	log_verbose using pyenv
	"$SCRIPT_DIR/install-pyenv.sh"
fi

if $ANACONDA; then
	log_verbose "use anaconda"
	"$SCRIPT_DIR/install-anaconda.sh"
fi

# autoimport - add and remove imports
# argparse complete
# bandit - check for security problems
# black - a very strick python formatter
# mypy - python type checking
# nptyping - types fo rnumpy
# pdoc3 - python documentation extraction from comments
# pydocstyle - python docstring style checker
# pytest - python test runner
# pyyaml - python yaml parser
# tox - python test runner for different versions of python
log_verbose development shell/python packages normally use pipenv but use anaconda instead
PYTHON_PACKAGES+=(

	argcomplete
	autocomplete
	autoimport
	bandit
	black
	flake8
	mypy
	nptyping
	pdoc3
	pydocstyle
	pytest
	pytest-cov
	pytest-timeout
	pytest-xdist
	pyyaml
	tox

)

# currently no python packages are needed
log_verbose "installing python packages ${PYTHON_PACKAGES[*]} in user mode and upgrade dependencies"

if [[ -n ${PYTHON_PACKAGES[*]} ]]; then
	pip_install --upgrade "${PYTHON_PACKAGES[@]}"
fi

log_verbose "User Site packages are in $(brew --prefix)/lib/python*/site-packages"

for version in "$OLD_PYTHON" "$NEW_PYTHON"; do
	log_verbose "Install other python $version"
	package_install "python$version"
done

# now put the completions in bashrc so subshells can find them like pipenv uses
# the --completion is removed as of Nov 2021 so there is a new way
#eval "$(pipenv --completion)"
# https://github.com/pypa/pipenv/issues/4860
if $PIPENV && ! config_mark "$(config_profile_shell)"; then
	config_add "$(config_profile_shell)" <<-'EOF'
		eval "$(_PIPENV_COMPLETE=bash_source pipenv)"
	EOF
fi
