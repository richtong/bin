#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Installs modular boost
## @author Rich Tong
## These are specific instructions for installing modular boost
## https://svn.boost.org/trac/boost/wiki/TryModBoost
## @returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# over kill for a single flag to debug, but good practice
OPTIND=1
# Set first because -r is the inverse so testing after getopts doesn't work
while getopts "hdvi:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: "usage: flags targets""
		echo "flags: d debug, -h help, -n dry run, -i installdir"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	i)
		INSTALL_DIR="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

INSTALL_DIR=${INSTALL_DIR:="WS_INSTALL_DIR"}
log_warning "WARNING Modular Boost does not install properly!!!!"

# now check for unknown variables
set -u

# Installation into the same directory as the source
if ! pushd "$SOURCE_DIR/externals/boost/boost"; then
	log_error 1 "no boost dir"
fi
# got this by looking at the bootstrap -h
rsync -a "$SOURCE_DIR/externals/boost/boost/" "$BUILD_DIR/externals/boost/boost"
./bootstrap.sh --prefix="$INSTALL_DIR" --exec-prefix="$INSTALL_DIR"
./b2 headers
./b2
popd || true

# validate the installation

if [ ! -e $INSTALL_DIR/include/boost ]; then
	echo $SCRIPTNAME: $INSTALL_DIR/include/boost installed
fi

if [ ! -e $INSTALL_DIR/lib/boost ]; then
	echo Boost librariesinstalled
fi
