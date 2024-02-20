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
ANACONDA="${ANACONDA:-true}"
PIPENV="${PIPENV:-true}"
POETRY="${POETRY:-true}"
# If version is set to null then the default python version is used
PYTHON_VERSION="${PYTHON_VERSION-}"
NEW_PYTHON="${NEW_PYTHON:-@3.10}"
# we normally don't need the oldest version
OLD_PYTHON="${OLD_PYTHON:-@3.8}"
PYENV="${PYENV:-false}"
OPTIND=1
# which user is the source of secrets
while getopts "hdvaeoyp:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install python components
			usage: $SCRIPTNAME [flags...]
			  -h help
			  -d $(! $DEBUGGING || echo "no ")debugging
			  -v $(! $VERBOSE || echo "not ")verbose
			  -a $(! $ANACONDA || echo "no ")anaconda install
			  -o $(! $POETRY || echo "no ")poetry install
			  -e $(! $PIPENV || echo "no ")pipenv install
			  -y $(! $PYENV || echo "no ")pyenv install
			  -p install python version (default: ${PYTHON_VERSION:-stable})
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
	a)
		ANACONDA="$($ANACONDA && echo false || echo true)"
		;;
	o)
		POETRY="$($POETRY && echo false || echo true)"
		;;
	e)
		PIPENV="$($PIPENV && echo false || echo true)"
		;;
	y)
		PYENV="$($PYENV && echo false || echo true)"
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

# Kite is Python code completer not used instead use Github copilot
# https://github.com/kiteco/jupyterlab-kite
# kite
# pydocstyle - no longer
PACKAGE+=(
	black
)

if [[ -v PYTHON_VERSION ]]; then
	log_verbose "will install $PYTHON_VERSION"
	PACKAGE+=("python$PYTHON_VERSION")
fi

if [[ $PYTHON_VERSION =~ @ ]]; then
	log_warning "Installing a python variant $PYTHON_VERSION"
	log_warning "This is keg-only and requires manually linking"
fi

# we need it to be python and pip to work and not python3 and pip3 only
# https://docs.brew.sh/Homebrew-and-Python
if ! config_mark; then
	# Use the brew location for python
	config_add <<-EOF
		# shellcheck disable=SC2155
		echo "\$PATH" | grep -q /opt/python$PYTHON_VERSION/libexec/bin || PATH="\$HOMEBREW_PREFIX/opt/python$PYTHON_VERSION/libexec/bin:\$PATH"
	EOF
	log_warning "source $(config_profile) to get the correct python"
fi

# add the correct python if not already there
# you cannot just source it again because this will
# cause the default paths to be put in before this path
#source_profile
#log_verbose "Pre PATH=$PATH"
[[ $PATH =~ $(brew --prefix)/opt/python$PYTHON_VERSION/libexec/bin ]] || PATH="$(brew --prefix)/opt/python$PYTHON_VERSION/libexec/bin:$PATH"
hash -r
export PATH
#log_verbose "PATH=$PATH"

if $POETRY; then
	log_verbose "Poetry for per project directory installed"
	PACKAGE+=(poetry)
fi
if $PIPENV; then
	PACKAGE+=(pipenv)
	log_verbose "use pipenv per project directory pipenv install"
fi

if $PYENV; then
	log_verbose "using pyenv"
	"$SCRIPT_DIR/install-pyenv.sh"
fi

if $ANACONDA; then
	log_verbose "use anaconda"
	"$SCRIPT_DIR/install-conda.sh"
fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing ${PACKAGE[*]}"
# packages are ok globbed
# shellcheck disable=SC2086
package_install "${PACKAGE[@]}"
log_verbose "black needs keg link"
# brew link pydocstyle
brew link black
#log_verbose "PATH=$PATH"

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
# mkdocs - documents made easy
# mkdocs-material - Add material design to documentation
# pymdown-extensions - Markdown helpers
# fontaweseom-markdown - emojis
log_verbose "development shell/python packages normally use pipenv but use anaconda instead"
PYTHON_PACKAGE+=(

	argcomplete
	autocomplete
	autoimport
	bandit
	black
	flake8
	mkdocs
	mkdocs-material
	pymdown-extensions
	fontawesome-markdown
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

if [[ -n ${PYTHON_PACKAGE[*]} ]]; then
	log_verbose "installing python packages ${PYTHON_PACKAGE[*]} in the base system and upgrade dependencies"
	pip_install --upgrade "${PYTHON_PACKAGE[@]}"
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
# fixed as o July 2022 and this causes a long pause in ssh when in .bashrc
#if $PIPENV && ! config_mark "$(config_profile_shell)"; then
#    config_add "$(config_profile_shell)" <<-'EOF'
#        eval "$(_PIPENV_COMPLETE=bash_source pipenv)"
#    EOF
#fi
