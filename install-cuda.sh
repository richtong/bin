#!/usr/bin/env bash
#
# Installs the  nVidia CUDA toolkit drivers
# This is no long use but install CUDA on top of nVidia drivers
# No long used
#
eet -u && SCRIPTNAME="$(basename "$0")"
trap 'exit $?' ERR

SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1


# No long used use the Run system
CUDA_URL_75=${CUDA_URL_75:-"http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_7.5-18_amd64.deb"}
# MD5 checksum is for the full download, so do not use
# CUDA_MD5SUM_75=${CUDA_MD5SUM_75:-"e810ded23efe35e3db63d2a92288f922"}
# This is for the network installer
CUDA_MD5SUM_75=${CUDA_MD5SUM_75:-"a44826d7783d4ee4c8ec346153c88d69"}

CUDA_RUN_URL_75=${CUDA_RUN_URL_75:-"http://developer.download.nvidia.com/compute/cuda/7.5/Prod/local_installers/cuda_7.5.18_linux-run"}
CUDA_RUN_MD5SUM_75=${CUDA_RUN_MD5SUM_75:-"4b3bcecf0dfc35928a0898793cf3e4c6"}


# This checksum is for the local installer not the network one
#CUDA_MD5SUM=${CUDA_MD5SUM:-"664fdf313e2c21cceb49b6f6957bf971"}
CUDA_URL_8="${CUDA_URL:-"http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_8.0.44-1_amd64.deb"}"
CUDA_URL_8="${CUDA_URL:-"http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/cuda-repo-ubuntu1404_8.0.44-1_amd64.deb"}"
CUDA_MD5SUM_8="${CUDA_MD5SUM:-"aac9771df4b0e11879434b0439aed227"}"
CUDA_RUN_URL_8="${CUDA_RUN_URL_8:-"https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run"}"
CUDA_RUN_MD5SUM_8="${CUDA_RUN_MD5SUM_8:-"33e1bd980e91af4e55f3ef835c103f9b"}"

# Use Cuda 8 by default
CUDA_VERSION=${CUDA_VERSION:-8}
CUDA_URL="${CUDA_URL:-"$CUDA_URL_8"}"
CUDA_MD5SUM="${CUDA_MD5SUM:-"$CUDA_MD5SUM_8"}"

while getopts "hdvm:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install proprietary nvidia cuda drivers
            echo "flags: -d debug -v verbose -h help"
            echo "       -m [ distro  | package | runfile ]"
            echo "          distro - use package included in distribution"
            echo "          package - download debian package from nvidia.com"
            echo "          runfile - download standalone file and run it from nvidia.com"
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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

set -u

if ! in_os linux
then
    log_exit "linux only"
fi

if ! has_nvidia
then
    log_exit "no nvidia"
fi


log_verbose install cuda

# https://stackoverflow.com/questions/28039372/bash-set-u-allow-single-unbound-variable
# So we use ${VAR-} to mean substitute a null string if it doesn't exist
# So this works with the set -u check
if [[  ${LD_LIBRARY_PATH-} =~ cuda ]]
then
    log_exit "cuda already installed in $LD_LIBRARY_PATH"
fi

# Some installs deliver cuda but the LD_LIBRARY_PATH
# is not set
if command -v nvcc
then
    log_warning $(nvcc --version | tail -1)
    log_warning "installed but not visible in LD_LIBRARY_PATH, trying to reinstall"
fi

# need bc for floating point and bc returns 0 or 1 so use (( )) to convert to true or false
# https://stackoverflow.com/questions/8654051/how-to-compare-two-floating-point-numbers-in-bash
package_install bc
log_verbose determining installation method
if in_linux ubuntu
then
    METHOD=${METHOD:-package}
elif in_linux debian && (( $(echo "$(lsb_release -sr) >= 9" | bc -l) ))
then
    log_warning Debian 9 aka Stretch can install from distro but does not seem to work
    METHOD=${METHOD:-distro}
else
    METHOD=${METHOD:-runfile}
fi
log_verbose installing by $METHOD method

# Neither package nor distro write to LD_LIBRARY_PATH
# usage: add_cuda_ld_library_path cuda_version
add_cuda_to_paths() {
    if (( $# < 1 )); then return 1; fi
    local cuda_version="$1"
    if ! grep "Added by $SCRIPTNAME" "$HOME/.profile"
    then
        tee -a "$HOME/.profile" <<-EOF
# Added by $SCRIPTNAME on $(date)
export PATH+=:/usr/local/cuda-$cuda_version/bin
export LD_LIBRARY_PATH+=:/usr/local/cuda-$cuda_version/lib
EOF
    fi
}

# Explains installation by package and runfile methods
# http://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#introduction
#
# Installation from distro from @vsadovsky in ws-master-Dockerfile
# http://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html#introduction
if [[ $METHOD =~ distro ]]
then

    package_install libclang-3.8-dev clang-3.8 llvm-3.8
    package_install nvidia-cuda-dev nvidia-cuda-toolkit python-pycuda
    sudo ldconfig
    add_cuda_to_paths "$CUDA_VERSION"
fi

if [[ $METHOD =~ package ]]
then
    # The debian package method from nvidia.com need to test
    deb_install nvidia-cuda "$CUDA_URL" "$(basename $CUDA_URL)" "$WS_DIR/cache" "$CUDA_MD5SUM"
    # The debian package method from nvidia.com
    # usage: download_url url [dest_file [dest_dir [md5 [sha256]]]]
    download_url "$CUDA_URL" "$(basename "$CUDA_URL")" "$WS_DIR/cache" "$CUDA_MD5SUM"
    sudo dpkg -i "$WS_DIR/cache/$(basename $CUDA_URL)"
    sudo apt-get update -y
    sudo apt-get install -y cuda
    log_warning the path may have changed for cuda from /usr/local/cuda-$CUDA_VERSION
    add_cuda_to_paths "$CUDA_VERSION"

fi

if [[ $METHOD =~ runfile ]]
then
    # The run method deprecated better to use packages
    download_url "$CUDA_RUN_URL" "$(basename "$CUDA_RUN_URL")" "$WS_DIR/cache" "$CUDA_RUN_MD5SUM"
    log_verbose fixing up the name from -run
    sudo "$WS_DIR/cache/$(basename $CUDA_RUN_URL | tr - . )" --silent --toolkit --override
fi

log_assert "nvcc --version" "cuda installation complete"

log_verbose reboot now to get latest nvidia driver and cuda $(nvcc --version)
