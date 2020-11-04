#!/usr/bin/env bash
##
## Installs the various docker containers for the big machine learning systems
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
MACHINE=${MACHINE:ml}
CUDA=${CUDA:-false}
ORG_NAME="${ORG_NAME:-tongfamily}"
while getopts "hdvc" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install machine learning docker images"
		echo "flags: -d debug -v verbose"
		echo "        -c install cuda images as well (default: $CUDA)"
		echo "        -m use docker-machine image (default: $MACHINE)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	c)
		CUDA=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh
set -u

# Use our own company image for tensorflow
IMAGES+=" $ORG_NAME/tensorflow "

# Use this rather tha Kai's weekly builds
IMAGES+=" tleyden5iwx/caffe-cpu-master "
if "$CUDA"; then
	IMAGES+=" tleyden5iws/caffe-gpu-master "
fi

# and https://hub.docker.com/r/kaixhin/cuda-pylearn2/
# others we do not install but which he builds regularly
# brainstorm digits fgmachine keras lasane mxnet spearmint
for f in torch pylearn2 neon theano lasagne; do
	IMAGES+=" kaixhin/$f "
	if "$CUDA"; then
		IMAGES+=" kaixhin/cuda-$f "
	fi
done

if ! docker ps; then
	if in_os mac; then
		if ! docker-machine status "$MACHINE" | grep Running; then
			docker-machine start "$MACHINE"
		fi
		eval "$(docker-machine env ml)"
	else
		log_warning no docker daemon found, did you docker daemon start
	fi
	exit 1
fi

for i in $IMAGES; do
	docker pull "$i"
	echo "run image for $(basename "$i")"
	if [[ $i =~ (cuda|gpu) ]]; then
		echo docker run -it --device /dev/nvidiactl --device /dev/nvidia-uvm --device /nvidia0 "$i"
	else
		echo docker run -it "$i"
	fi
done

if "$CUDA"; then
	log_warning docker cuda requires that the drivers in the host and the container have identical versions
	log_warning https://github.com/NVIDIA/nvidia-docker is the answer
fi
