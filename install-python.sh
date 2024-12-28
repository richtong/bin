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
ANACONDA="${ANACONDA:-false}"
PIPENV="${PIPENV:-false}"
POETRY="${POETRY:-true}"
UV="${UV:-true}"

NEW_PYTHON="${NEW_PYTHON:-@3.12}"
# we normally don't need the oldest version
OLD_PYTHON="${OLD_PYTHON:-@3.11}"
PYTHON_VERSION="${PYTHON_VERSION:-$OLD_PYTHON}"
PYENV="${PYENV:-false}"
OPTIND=1
# which user is the source of secrets
while getopts "hdvaeoyp:u" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install python and related commands and pip packages system wide
			using either homebrew or pipx

			Also installs other virtual environments optionally.

			If you are using asdf this will be into the execution, then depending on where the script is running
			it will install the specific shared shim.

			Note that if you install Anaconda, then that python version will mask the Homebrew version
			even if conda is not activated. So you need to manage the conda version at all times.

			usage: $SCRIPTNAME [flags...]
			  -h help
			  -d $(! $DEBUGGING || echo "no ")debugging
			  -v $(! $VERBOSE || echo "not ")verbose
			  -a $(! $ANACONDA || echo "no ")anaconda install
			  -o $(! $POETRY || echo "no ")poetry install
			  -e $(! $PIPENV || echo "no ")pipenv install
			  -y $(! $PYENV || echo "no ")pyenv install
			  -u $(! $UV || echo "no ")uv install
			  -p install python version (default: ${PYTHON_VERSION:-$OLD_PYTHON})
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
	u)
		UV="$($UV && echo false || echo true)"
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

# favor the brew packages vs pip
# autocomplete will not install in brew so must be in an environment remove it as not used much
# flake8 and black are replaced by ruff and ruff also does markdownlint so move
# to install-lint
# kite  # Kite is Python code completer not used use Codeium
# black  # formatter (replaced by ruff)
# flake8  # python linter (replaced by ruff)
# pydocstyle - no longer maintained use ruff (deprecated)
# pyyaml             # pyyaml - python yaml parser should be in each environment
# bandit             # check for security problems deprecated for ruff
PACKAGE+=(

	mypy               # mypy - python type checking
	pipx               # run python cli in venv
	python-argcomplete # argument parser
	ruff               # fast linter replaces flake8, pydocstyle, black
	tox                # tox - python test runner for different versions of python

)

if [[ -v PYTHON_VERSION ]]; then
	log_verbose "will install $PYTHON_VERSION"
	PACKAGE+=("python$PYTHON_VERSION")
fi

if [[ $PYTHON_VERSION =~ @ ]]; then
	log_warning "Installing a python variant $PYTHON_VERSION"
	log_warning "This is keg-only and requires manually linking"
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

if $UV; then
	log_verbose "use uv"
	PACKAGE+=(uv)
	PIPX_PACKAGE+=(poetry_to_uv)
fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing ${PACKAGE[*]}"
# packages are ok globbed
# shellcheck disable=SC2086
package_install "${PACKAGE[@]}"

# log_verbose "black needs keg link"
# brew link pydocstyle  # pydostyle no longer maintained
# brew unlink black && brew link black  # using ruff instead
#log_verbose "PATH=$PATH"

for version in "$OLD_PYTHON" "$NEW_PYTHON"; do
	log_verbose "Install other python $version"
	package_install "python$version"
done

# https://pipx.pypa.io/latest/installation/
# pipx make sure it can change global and local paths
log_verbose "ensurepath for globals"
pipx ensurepath
sudo pipx ensurepath --global

# pipx creates python cli in venv with PATH links so use for real python apps
# which need isolation, favor homebrew first then use pipx, if you wnat
# an installation just in a venv use pip install.
PIPX_PACKAGE+=(
	argcomplete
)
log_verbose "installing ${PIPX_PACKAGE[*]}"
pipx install "${PIPX_PACKAGE[@]}"

# These should only be command line utilities, not packages for python compute
# those packages should be installed in the venv system you are using

# install into user's python default installation
# these are onlyi available only as pip packages, we favor homebrew
#if ! command -v brew; then
#log_verbose "no homebrew so can install these packages but want everywhere so use pipx"
PIPX_PACKAGE+=(

	# autocomplete
	# pydantic - data validation and type checking integrates with mypy
	# pymdown-extensions - Markdown helpers
	# autoimport - add and remove imports
	# pdoc3 - python documentation extraction from comments (deprecated use ruff)
	# nptyping - types fo rnumpy
	# pyyaml # pyyaml - python yaml parser (moved from brew install)
	# pytest # pytest - python test runner
	# pytest-cov
	# pytest-timeout
	# pytest-xdist
	# types-requests ## mypy needs this for checking

)
#fi

# https://pipx.pypa.io/latest/installation/
# pipx make sure it can change global and local paths
pipx ensurepath
sudo pipx ensurepath --global

if [[ $(command -v python) =~ "conda" ]]; then
	log_warning "Anaconda is installed so pip packages will go into conda environment"
	log_warning "And not into the system base environment, usually homebrew"
	log_warning "you must comment out the conda activation lines in .bash_profile and .zshrc"
	log_warning "to change the system or homebrew python environments"
elif [[ $(command -v python) =~ "asdf" ]]; then
	log_warning "Running in an asdf environment for the script directory"
	log_warning "pip packages will go into the asdf python environment"
	log_warning "to install the in the system or homebrew python environment you"
	log_warning "should installation outside of an asdf environment where an .tool-versions file exists"
fi

# should not be set as pipx is preferred
if [[ -n ${PYTHON_PACKAGE[*]} ]]; then
	# this is no longer needed
	# if in_os mac; then
	# https://stackoverflow.com/questions/12744031/how-to-change-values-of-bash-array-elements-without-loop
	#	log_verbose "In MacOS, use brew not raw pip install into system, use  brew install ${@/#/python-}"
	# note # means ^ and % means $ because these are already special to bash
	#		brew_install "${PYTHON_PACKAGE[@]/#/python-}"
	#else
	log_verbose "installing python packages ${PYTHON_PACKAGE[*]} in the base system and upgrade dependencies"
	pip_install --upgrade "${PYTHON_PACKAGE[@]}"
	# fi
fi

log_verbose "installing ${PIPX_PACKAGE[*]}"
pipx_install "${PIPX_PACKAGE[@]}"

# we need it to be python and pip to work and not python3 and pip3 only
# https://docs.brew.sh/Homebrew-and-Python
# do not hard link this as its not flexible python3 is in Homebrew
#  so instead of this you shoud alias python=python3
# echo "\$PATH" | grep -q /opt/python$PYTHON_VERSION/libexec/bin || PATH="\$HOMEBREW_PREFIX/opt/python$PYTHON_VERSION/libexec/bin:\$PATH"
# https://github.com/pypa/pipx/issues/330
# completions are supposed to be installed by homebrew for pipx now except for zsh
for profile in "$(config_profile_nonexportable_zsh)" "$(config_profile_nonexportable_bash)"; do
	if ! config_mark "$profile"; then
		log_verbose "adding to $profile alias python=python3 if python3 exists and python does not"
		config_add "" <<-EOF
			if ! command -v python >/dev/null && command -v python3; then alias python=python3; fi
			if command -v pipx >/dev/null; then eval "$(register-python-argcomplete pipx)"; fi
		EOF
	fi
done

log_verbose "User Site packages are in $(brew --prefix)/lib/python*/site-packages"

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
