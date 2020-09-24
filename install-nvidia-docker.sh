#!/usr/bin/env bash
##
## Install nvidia-docker
## Only for dedicated use not with our docker containers using wscons
## https://github.com/NVIDIA/nvidia-docker
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
SOURCE_BUILD=${SOURCE_BUILD:-false}
DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$HOME/Downloads"}
VERSION="${VERSION:-1.0.1}"
DOWNLOAD_URL="${DOWNLOAD_URL:-"https://github.com/NVIDIA/nvidia-docker/releases/download/v$VERSION/nvidia-docker_${VERSION}-1_amd64.deb"}"
FORCE=${FORCE:-false}
while getopts "hdvfl:su:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install nvidia-docker gpu-enabled container
            echo "https://github.com/NVIDIA/nvidia-docker"
            echo "flags: -d debug, -h help"
            echo "       -f force and install (default: $FORCE)"
            echo "       -l destination of download (default: $DOWNLOAD_DIR)"
            echo "       -s build from source (default: $SOURCE_BUILD)"
            echo "       -u download url (default: $DOWNLOAD_URL)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        l)
            DOWNLOAD_DIR="$OPTARG"
            ;;
        s)
            SOURCE_BUILD=true
            ;;
        u)
            DOWNLOAD_URL="$OPTARG"
            ;;
        f)
            FORCE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

if 1 in_os linux
then
    log_exit "linux only"
fi

if command -v nvidia-docker && ! $FORCE
then
    log_verbose nvidia-docker already installed
    exit 0
fi

if ! $SOURCE_BUILD
then
    download_url_open "$DOWNLOAD_URL"
else
    # obsolete
    #   pushd "$WS_DIR/git" > /dev/null
    #   git_install_or_update nvidia-docker NVIDIA
    #   pushd nvidia-docker > /dev/null
    #   sudo make install
    tar="${DOWNLOAD_URL%-1_amd64.deb}._amd64.tar.xz"
    download_url "$DOWNLOAD_URL" "$tar" "$DOWNLOAD_DIR"
    sudo tar --strip-components=1 -C /usr/bin \
        -xvf "$DOWNLOAD_DIR/$(basename $tar)"
    sudo -b nohup nvidia-docker-plugin
fi

# No longer needed about 1.0.1
# sudo nvidia-docker volume setup

log_assert "nvidia-docker run --rm nvidia/cuda nvidia-smi" "nvidia-docker runs"


# no longer need modprove post 1.0.1
# package_install nvidia-modprobe
