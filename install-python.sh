#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
## Install Python related pieces
##
##
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
# need to use trap and not -e so bashdb works
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
ANACONDA="${ANACONDA:-true}"
PIPENV="${PIPENV:-true}"
PYTHON_VERSION="${PYTHON_VERSION:-3.10j}"
STABLE_PYTHON="${STABLE_PYTHON:-3.9}"
# we normally don't need the oldest version
OLD_PYTHON="${OLD_PYTHON:-3.8}"
PYENV="${PYENV:-false}"
OPTIND=1
# which user is the source of secrets
while getopts "hdvaey" opt; do
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

if [[ -v PYTHON_VERSION ]]; then
	PACKAGES+=("python@$PYTHON_VERSION")
fi

PACKAGES=(
	black
	pydocstyle
)

log_verbose "added to config now source"
source_profile
hash -r

if $PIPENV; then
	PACKAGES+=(pipenv)
	log_verbose "use pipenv per directory pipenv install"
fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing ${PACKAGES[*]}"
# packages are ok globbed
# shellcheck disable=SC2086

package_install "${PACKAGES[@]}"

if $PYENV; then
	log_verbose using pyenv
	"$SCRIPT_DIR/install-pyenv.sh"
fi

if $ANACONDA; then
	log_verbose "use anaconda"
	"$SCRIPT_DIR/install-anaconda.sh"
fi

# argparse complete
log_verbose development shell/python packages normally use pipenv but use anaconda instead
PYTHON_PACKAGES+=(
	argcomplete
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

for version in "$OLD_PYTHON" "$STABLE_PYTHON"; do
	log_verbose "Install Old python $version"
	package_install "python@$version"
done

# we need it to be python and pip for compatibility with Linux
# https://docs.brew.sh/Homebrew-and-Python
if ! config_mark; then
	# Use the brew location for python
	config_add <<-'EOF'
		# shellcheck disable=SC2155
		[[ $PATH =~ $(brew --prefix)/opt/python/libexec/bin ]] || export PATH="$(brew --prefix)/opt/python/libexec/bin:$PATH"
	EOF
	log_warning "source $(config_profile) to get the correct python"
fi

# now put the completions in bashrc so subshells can find them like pipenv uses
if $PIPENV && ! config_mark "$(config_profile_shell)"; then
	config_add "$(config_profile_shell)" <<-'EOF'
		eval "$(pipenv --completion)"
	EOF
fi
