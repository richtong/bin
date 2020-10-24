#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
# Install prerquisites for Berkeley CAFFE package
# ## see http://caffe.berkeleyvision.org/installation.html
# http://caffe.berkeleyvision.org/install_apt.html
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install caffe"
		echo "flags: -d debug, -v verbose, -h help"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

"$SCRIPT_DIR/install-nvidia.sh"

sudo apt-get install -y \
	libprotobuf-dev \
	libleveldb-dev \
	libsnappy-dev \
	libopencv-dev \
	libhdf5-serial-dev \
	protobuf-compiler

sudo apt-get install --no-install-recommends libboost-all-dev

sudo apt-get -y install libopenblas-base libopenblas-dev

sudo apt-get -y install python-dev

sudo apt-get -y install \
	libgoogle-glog-dev \
	libgflags-dev \
	liblmdb-dev

sudo apt-get -y install cmake

git_install_or_update caffe bvlc

mkdir -p "$WS_DIR/var/caffe"
pushd "$WS_DIR/var/caffe" >/dev/null
cmake "$GIT_DIR/caffe"
make all
make install
make runtest
popd >/dev/null
