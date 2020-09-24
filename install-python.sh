#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
## Install Python related pieces
##
##
#
set -u && SCRIPTNAME=$(basename $0)
# need to use trap and not -e so bashdb works
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
ANACONDA="${ANACONDA:-false}"
NO_PIPENV="${NO_PIPENV:-false}"
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
  -a install anaconda to manage python and packages (default: $ANACONDA)
  -e disable pipenv to manage packages (default: $NO_PIPENV)
  -y install pyenv to manage python versions (default: $PYENV)
EOF

            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        a)
            ANACONDA=true
            ;;
        e)
            NO_PIPENV=true
            ;;
        y)
            PYENV=true
            ;;
    esac
done
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
log_verbose WS_DIR is $WS_DIR
source_lib lib-util.sh lib-config.sh lib-install.sh
shift $((OPTIND-1))

if ! in_os mac
then
    log_exit "Mac only"
fi

PACKAGES=" python@3.7 python@3.8 "

if ! $NO_PIPENV
then
    PACKAGES+=" pipenv "
fi

# Note do not quote, want to process each as separate arguments
log_verbose installing $PACKAGES
package_install $PACKAGES

# https://stackoverflow.com/questions/19340871/how-to-link-home-brew-python-version-and-set-it-as-default
# this defeats the homebrew strategy that python is the default MacOS while python2 and pip2 are homebrew
# we need it to be python and pip for compatibility with Linux
if ! config_mark
then
    log_verbose adding homebrew python $(config_profile)
    config_add <<-"EOF"
[[ $PATH =~ /usr/local/opt/python/libexec/bin ]] || export PATH="/usr/local/opt/python/libexec/bin:$PATH"
EOF
fi

if $PYENV
then
    log_verbose using pyenv
    "$SCRIPT_DIR/install-pyenv.sh"
fi

if $ANACONDA
then
    log_verbose  use anaconda
    "$SCRIPT_DIR/install-anaconda.sh"
fi
