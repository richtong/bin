#!/usr/bin/env bash
##
## install Bazel builder
## https://docs.bazel.build/versions/master/install.html
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
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Bazel builder
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"

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
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh


if in_os mac
then
    log_verbose mac install
    if ! command -v brew
    then
        "$SCRIPT_DIR/install-brew.sh"
    fi
    log_verbose installing Java 8 or higher
    # https://stackoverflow.com/questions/24342886/how-to-install-java-8-on-mac
    cask_install java
    log_verbose install bazel
else

    log_verbose linux install
    if in_linux ubuntu && [[ linux_version =~ ^14 ]]
    then
        log_verbose installing ppa for java
        # usage: repository_install [team/repo | single_repo string]
        repository_install ppa:webupd8team/java
        package_install oracel-java8-installer
    else
        log_verbose install java 8 jdk
        package_install openjdk-8-jdk
    fi
    log_verbose adding Bazel gpg
    curl https://bazel.build/bazel-release.pub.gpg | sudo apt-key add -
    log_verbose adding Bazel repo
    repository_install "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8"
fi

package_install bazel
log_assert "command -v bazel" "Bazel installed"
log_exit "Bazel installed"
