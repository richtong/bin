#!/usr/bin/env bash
##
## install older versions of Java
## Old version of Java needed by older software, like unifi 4.11.47
## https://stackoverflow.com/questions/24342886/how-to-install-java-8-on-mac
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
VERSION="${VERSION:-8}"
TAP="${TAP:-"adoptopenjdk/openjdk"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Java SDK
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
           -r version number (default: $VERSION)
              available versions are 8, 9, 10, and 11
           -t tap for all jdks (default: $TAP)
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
        r)
            VERSION="$OPTARG"
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh

if ! in_os mac
then
    log_exit "Mac only"
fi

log_verbose as of June 2019 can no longer install from Oracle
log_verbose and there is a conflict version 8 in homebrew
log_verbose conflicts with the same version in adoptopenjdk
if [[ $VERSION != 8 ]]
then
    log_verbose tapping $TAP
    tap_install "$TAP"
elif brew tap | grep -q "$TAP"
then
    log_verbose version 8 is is duplicationed in $TAP so remove
    brew untap "$TAP"
fi
log_verbose installing "adoptopenjdk$VERSION"
cask_install "adoptopenjdk$VERSION"

log_verbose install jenv and add all java versions
"$SCRIPT_DIR/install-jenv.sh"

log_verbose check to see if jenv already has versions skipping the first line which is always system
if [[ $(jenv versions | tail -n +2) == "" ]]
then
    # note we use find because if there are no files that match
    # then ls returns the string whereas find returns null and suppress error
    # messages
    for d in $(find "/Library/Java/JavaVirtualMachines/*/Contents/Home" -depth 0 2>/dev/null)
    do
        log_verbose "Adding to jenv: $d"
        jenv add "$d"
    done
fi
