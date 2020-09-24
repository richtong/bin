#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install Caffe for vision recognition
## see http://caffe.berkeleyvision.org/installation.html
## @author rich
#

set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# over kill for a single flag to debug, but good practice
OPTIND=1
while getopts "hdvd:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: -d debug, -h help
            echo "  -c cuda download url"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        c)
            CUDA_DOWNLOAD="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-version-compare.sh

CUDA_DOWNLOAD=${CUDA_DOWNLOAD:="http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda-repo-ubuntu1404-7-5-local_7.5-18_amd64.deb"}
set -u

# Install CUDA
# See http://www.r-tutor.com/gpu-computing/cuda-installation/cuda7.5-ubuntu
# Version is too old in 14.04 with `sudo apt-get isntall nvidia-cuda-toolkit`
# Check version $nvcc --version, preferred 6.0 or higher

if ! command -v nvcc
then
    if [[ $(lsb_release -d) == "Ubuntu" ]] && vergte $(lsb_release -rs) 14.04
    then
        mkdir -p "$CACHE_ROOT_DIR"
        pushd "$CACHE_ROOT_DIR"
        BASENAME=$(basename "$CUDA_DOWNLOAD")
        [ -e "$BASENAME" ] || wget "$CUDA_DOWNLOAD"
        sudo dpkg -i "$CACHE_ROOT_DIR/$BASENAME"
        sudo apt-get -y update
        sudo apt-get install -y cuda
        popd
        if verlte $(nvcc --version) 6.0
        echo $SCRIPTNAME: cuda is too old at $(nvcc --version)
        exit 1
    fi
fi
fi

1.1.2 Latest is 7.0
Recommended by CAFFE to use 6.x or 7.0. Need to install from nvidia site

1.1.2.1 Validate compat
$update-pciids
$lspci | grep -i nvidia

Validate against http://developer.nvidia.com/cuda-gpus

1.1.2.2 Download CUDA toolkit http://developer.nvidia.com/cuda-downloads , install DEB package

Download local packge for 14.04 or 14.10, matching distro

$wget http://developer.download.nvidia.com/compute/cuda/7_0/Prod/local_installers/rpmdeb/cuda-repo-ubuntu1410-7-0-local_7.0-28_amd64.deb


$sudo dpkg -i cuda-repo-ubuntu1404-7-0_local_7.0-28_amd64.deb
$sudo apt-get update
$sudo apt-get install cuda
$sudo apt-get install cuda-drivers

*May need to uninstall CUDA toolkit components and libraries (5.5) using apt-get remove

If installing into different location from /usr/local make sure to modify CAFFE makefile.config setting CUDA_DIR

1.1.2.3 Set up environment
$export PATH=/usr/local/cuda/bin:$PATH
$export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

1.1.2.4 Validate installation
$cat /proc/driver/nvidia/version
$nvcc --version

Get compiled binary deviceQuery from CUDA utilities kit , copied into source/bin

$deviceQuery

Should produce output like

./deviceQuery Starting...

CUDA Device Query (Runtime API) version (CUDART static linking)

Detected 1 CUDA Capable device(s)

Device 0: "GeForce GTX 970"
CUDA Driver Version / Runtime Version          7.0 / 7.0
CUDA Capability Major/Minor version number:    5.2
Total amount of global memory:                 4095 MBytes (4294246400 bytes)
(13) Multiprocessors, (128) CUDA Cores/MP:     1664 CUDA Cores

1.1.2.5 Optional install of nVidia NN library
cuDNN <<TBD>>
Will need to add cuDNN setting to makefile.conf later

1.2 BLAS
OpenBLAS is in Ubuntu
$sudo apt-get install libopenblas-base libopenblas-dev

Alternative1 (CPU based) is Intel optimized MKL

Alternative2 (GPU based) is cuBlas library, included in CUDA SDK 7

1.3 Boost
Latest version is 1.58 - install script is in source/scripts/extinstall/install-boost.sh. Default prefix is /usr/local

export SRC_PUB_ROOT=~/src.pub
mkdir -pv $SRC_PUB_ROOT
cd $SRC_PUB_ROOT
wget -c 'http://sourceforge.net/projects/boost/files/boost/1.58.0/boost_1_58_0.tar.bz2/download'
tar xf download
cd boost_1_58_0/
./bootstrap.sh --show-libraries
sudo ./bootstrap.sh
sudo ./b2
sudo ./b2 install --prefix=/usr/local

1.4 OpenCV >= 2.4.8

Preferably build 3.0 in our tree (scons opencv)


1.5 Google packages
$sudo apt-get install libprotobuf8 libprotobuf-dev libprotoc-dev protobuf-compiler
$sudo apt-get install libgoogle-glog-dev libgoogle-glog-doc libgoogle-glog0  glogg
$sudo apt-get install libgflags-dev libgflags-doc libgflags2

1.6 Data management packages

Use source/scripts/extinstall/install-caffe.sh or manually per below

HDF5
$sudo apt-get install libhdf5-7 libhdf5-dev libhdf5-doc h5utils hdf5-tools hdf5-helpers hdfview

LEVELDB
$sudo apt-get install leveldb-doc libleveldb-dev libleveldb1 libmtbl-dev libmtbl0

SNAPPY
$sudo apt-get install libsnappy-dev libsnappy1

LMDB
$sudo apt-get install liblmdb-dev liblmdb0 lmdb-doc lmdb-utils

2. Clone and build CAFFE

$git clone --recursive --recurse-submodules github.com:BVLC/caffe.git

2.1 Review and modify makefile.config

2.2 Build
$make all
$make test
$make runtest

2.3 Python
$sudo apt-get install python-virtualenv python-pip  python-numpy python-scipy
$sudo apt-get install libblas-dev
$sudo apt-get install liblapack-dev
$sudo apt-get install gfortran
$sudo apt-get install libatlas-dev liblapack-pic libatlas-base-dev libatlas-cpp-0.6-1 libatlas3-base
$sudo pip install pyyaml flask scikit-image

## !!! IMPORTANT to create python package !!!
make pycaffe

$cd CAFFE_ROOT/python
$for req in $(cat requirements.txt); sudo do pip install $req; done

### Repeat above for every python sample

$cmake -f CMakeLists.txt
$make

3. Run test tutorial

3.0 Verify caffe recognition works with pretrained model

Download Reference CaffeNet Model and the ImageNet Auxiliary Data:

cd <caffe_directory>

    ./scripts/download_model_binary.py models/bvlc_reference_caffenet
    ./data/ilsvrc12/get_ilsvrc_aux.sh

Running `python examples/web_demo/app.py` will bring up the demo server, accessible at `http://0.0.0.0:5000`.
You can enable debug mode of the web server, or switch to a different port (run -h option)

    $python examples/web_demo/app.py

web UI allows uoloading image and classifying it

3.1 MNIST

3.2 IMAGENET
