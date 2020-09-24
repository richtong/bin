#!/usr/bin/env bash
##
## install Intel OpenCL SRB 5 package for Ubuntu 16/Debian 9
## http://registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB5.0_intel-opencl-installation.pdf
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install Intel OpenCL SRB 5 Debian 9/Ubuntu 16, 4.8 kernel
            echo "flags: -d debug, -v verbose, -h help"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done

set -u

cd /tmp
mkdir -p intelopencl
cd intelopencl
rm -fr *

echo Downloaing an archive ...
sudo apt-get -y update
sudo apt-get -y install xz-utils

wget http://registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB5.0_linux64.zip

echo Unarchiving ...

unzip SRB5.0_linux64.zip

export BUILD_ID=63503

mkdir intel-opencl
tar -v -C intel-opencl -Jxf intel-opencl-r5.0-$BUILD_ID.x86_64.tar.xz
tar -v -C intel-opencl -Jxf intel-opencl-devel-r5.0-$BUILD_ID.x86_64.tar.xz
tar -v -C intel-opencl -Jxf intel-opencl-cpu-r5.0-$BUILD_ID.x86_64.tar.xz

echo Installing binaries ...
sudo cp -R intel-opencl/* /
sudo ldconfig

echo Done...
