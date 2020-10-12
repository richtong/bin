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
NO_ANACONDA="${NO_ANACONDA:-false}"
NO_PIPENV="${NO_PIPENV:-false}"
PYTHON_VERSION="${PYTHON_VERSION:-3.9}"
STABLE_PYTHON="${STABLE_PYTHON:-3.7}"
PYENV="${PYENV:-false}"
OPTIND=1
# which user is the source of secrets
while getopts "hdvaey" opt
do
    case "$opt" in
        h)
            cat <<-EOF

Install python components

usage: $SCRIPTNAME [flags...]

  -h help
  -v verbose
  -d single step debugging
  -a disable anaconda to manage python and packages (default: $NO_ANACONDA)
  -e disable pipenv to manage packages (default: $NO_PIPENV)
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
            NO_ANACONDA=true
            ;;
        e)
            NO_PIPENV=true
            ;;
        y)
            PYENV=true
            ;;
        *)
            echo "no -$opt flag" >&2
    esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh lib-install.sh
shift $((OPTIND-1))

if ! in_os mac
then
    log_exit "Mac only"
fi

PACKAGES=" python@$STABLE_PYTHON python@$PYTHON_VERSION "

if ! $NO_PIPENV
then
    PACKAGES+=" pipenv "
fi

# Note do not quote, want to process each as separate arguments
log_verbose "installing $PACKAGES"
# packages are ok globbed
# shellcheck disable=SC2086
package_install $PACKAGES

# we need it to be python and pip for compatibility with Linux
if ! config_mark
then
    log_verbose "adding homebrew python $(config_profile)"
    config_add <<-"EOF"
[[ $PATH =~ /usr/local/opt/python@$PYTHON_VERSION/libexec/bin ]] || export PATH="/usr/local/opt/python@$PYTHON_VERSION/libexec/bin:$PATH"
EOF
fi

if $PYENV
then
    log_verbose using pyenv
    "$SCRIPT_DIR/install-pyenv.sh"
fi

if ! $NO_ANACONDA
then
    log_verbose "use anaconda"
    "$SCRIPT_DIR/install-anaconda.sh"
fi
