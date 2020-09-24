#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Installs modular boost
## @author Rich Tong
## These are specific instructions for installing modular boost
## https://svn.boost.org/trac/boost/wiki/TryModBoost
## @returns 0 on success
#
set -e && . `dirname $0`/ws-env.sh && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# over kill for a single flag to debug, but good practice
OPTIND=1
# Set first because -r is the inverse so testing after getopts doesn't work
while getopts "hdvi:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: "usage: flags targets"
            echo "flags: d debug, -h help, -n dry run, -i installdir"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        i)
            INSTALL_DIR="$OPTARG"
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

INSTALL_DIR=${INSTALL_DIR:="WS_INSTALL_DIR"}
echo $SCRIPTNAME: WARNING Modular Boost does not install properly!!!!

# now check for unknown variables
set -u

# Installation into the same directory as the source
pushd "$SOURCE_DIR/externals/boost/boost"
# got this by looking at the bootstrap -h
rsync -a "$SOURCE_DIR/externals/boost/boost/" "$BUILD_DIR/externals/boost/boost"
./bootstrap.sh --prefix="$INSTALL_DIR" --exec-prefix="$INSTALL_DIR"
./b2 headers
./b2
popd

# validate the installation

if [ ! -e $INSTALL_DIR/include/boost ]
then
    echo $SCRIPTNAME: $INSTALL_DIR/include/boost installed
fi

if [ ! -e $INSTALL_DIR/lib/boost ]
then
    echo Boost librariesinstalled
fi
