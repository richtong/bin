#!/usr/bin/env bash
##
## install mac hugin and enblend and autopan-sift-c
## http://wiki.panotools.org/Hugin_Compiling_OSX
## http://wiki.panotools.org/Enblend_Compiling_OSX
## http://wiki.panotools.org/Autopano-sift-C_Compiling_OSX
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
MAKEFLAGS=${MAKEFLAGS:-"j4"}
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install hugin and enblend
            echo "flags: -d debug, -v verbose, -h help"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u
shift $((OPTIND-1))

if ! in_os mac
then
    log_error 1 "only on Mac"
fi

if cask_install hugin
then
    log_exit "Brew installed hugin cask"
fi

if ! command -v port
then
    log_error 1 "brew failed and no port command"
fi

sudo port selfupdate
sudo port -d sync

# Getting an error when mercurial installed, so need to run this
sudo port -f activate py27-docutils

# wxWidgets-2.8 obsolete on El Capitan
# https://forums.wxwidgets.org/viewtopic.php?t=38338
sudo port install cmake boost tiff jpeg libpng subversion openexr \
    exiv2 glew mercurial tclap libpano13 wxWidgets-3.0 python27

sudo port select --set python python27

# http://stackoverflow.com/questions/35610166/why-cant-cmake-find-a-package-installed-using-mac-ports
sudo port select --set wxWidgets wxWidgets-3.0

# Hugvin dependencies not previously documented need for vigra and py27-six is
# required and had an issue
sudo port -f activate py27-six
sudo port install vigra

# Hugin uses OpenMP so we need gcc
# http://mathcancer.blogspot.com/2016/01/PrepOSXForCoding-MacPorts.html
sudo port install gcc5
sudo port select --set gcc mp-gcc5

# recognize the command changes
hash -r

hg_install "http://hg.code.sf.net/p/hugin/hugin"


mkdir -p "$WS_DIR/var/hugin"
pushd "$WS_DIR/var/hugin"
export CFLAGS="-I/opt/local/include -L/opt/local/lib"
export CXXFLAGS="$CFLAGS"
cmake "$WS_DIR/git/hugin"
make
sudo make install
popd

log_verbose building enblend

sudo port install make lcms boost jpeg tiff libpng OpenEXR mercurial

hg_install "http://enblend.hg.sourceforge.net:8000/hgroot/enblend"
pushd enblend
make --makefile=Makefile.scm
popd

mkdir -p "$WS_DIR/var/enblend"
pushd "$WS_DIR/var/enblend"
export CPPFLAGS="-I/opt/local/include"
export LDFLAGS="-L/opt/local/lib"
"$WS_DIR/git/enblend/configure --with-apple-opengl-framework"
make
sudo make install

log_verbose install autopano-sift-c

sudo port install cmake libtool jpeg tiff libpng

mkdir -p "$WS_DIR/git"
pushd "$WS_DIR/git"
svn co https://pantools.svn.sourceforge.net/svnroot/panotools/trunk/libpano libpano13
pushd libpano13
export LIBTOOLIZE=glibtoolize
./bootstrap
./configure --with-jpeg=/opt/local/ --with-tiff=/opt/local/ --with-png=/opt/local/
make
popd
popd

hg clone http://hugin.hg.sourceforge.net/hgweb/hugin/autopano-sift-C autopano-sift-C
mkdir -p "$WS_DIR/var/autopano-sift-C"
pushd "$WS_DIR/var/autopan-sift-C"
cmake -DCMAKE_INSTALL_PREFIX-/usr/local "$WS_DIR/git/autopano-sift-C"
make
sudo make install
popd


sudo make install
