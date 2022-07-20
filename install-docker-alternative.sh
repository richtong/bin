#!/usr/bin/env bash
##
## Install Podman and Lima instead of Docker
## https://podman.io/getting-started/installation
## https://blog.mornati.net/lima-vm-docker-desktop-alternative-for-macosx
## https://github.com/lima-vm/lima
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
QEMU="${QEMU:-true}"
PODMAN="${PODMAN:-false}"
MULTIPASS="${MULTIPASS:-false}"
LIMA="${LIMA:-false}"
COLIMA="${COLIMA:-true}"
COLIMA_STABLE="${COLIMA_STABLE:-false}"
KUBERNETES="${KUBERNETES:-false}"
RANCHER="${RANCHER:-false}"
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
while getopts "hdvqpmclsrk" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Docker alternatives and running Linux on Mac
				- Podman is Redhat's CLI replacement for docker
				- Lima is an open source replacement for a linux VM with full
				  sharing to Linux, like Linux Subsystem for Mac (ala WSL)
				- Colima uses Lima to emulate docker exactly
				- Multipass is Ubuntu virtual machines for bare metal
				- Rancher Desktop is a graphical replacement for Docker Desktop

				usage: $SCRIPTNAME [ flags ]
				flags:
					   -h help
					   -d $($DEBUGGING || echo "no ")debuggging
					   -v $($VERBOSE || echo ""not "")verbose
					   -q QEMU $($QEMU && echo "not ")installed
					   -p Podman $($PODMAN && echo "not ")installed
					   -m Multipass $($MULTIPASS && echo "not ")installed
					   -l Lima $($LIMA && echo "not ")installed
					   -c Colima $($COLIMA && echo "not ")installed
					   -s Colima $($COLIMA_STABLE && echo dev || echo stable) release installed
					   -k Kubernetes $($KUBERNETES && echo not) installed
					   -r Rancher Desktop $($RANCHER && echo "not ")installed
		EOF
		exit 0
		;;
	d)
		export DEBUGGING="$DEBUGGING && echo false || echo true"
		;;
	v)
		export VERBOSE="$VERBOSE && echo false || echo true"
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	q)
		QEMU="$QEMU && echo false || echo true"
		;;
	m)
		MULTIPASS="$MULTIPASS && echo false || echo true"
		;;
	p)
		PODMAN="$PODMAN && echo false || echo true"
		;;
	l)
		LIMA="$LIMA && echo false || echo true"
		;;
	c)
		COLIMA="$COLIMA && echo false || echo true"
		;;
	s)
		COLIMA_STABLE="$COLIMA_STABLE && echo false || echo true"
		;;
	r)
		RANCHER="$RANCHER && echo false || echo true"
		;;
	k)
		KUBERNETES="$KUBERNETES && echo false || echo true"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-config.sh

log_verbose "LIMA=$LIMA"

if $LIMA; then
	log_verbose "Installing Lima"
	log_warning "On M1 Mac this fails and may need a reboot"
	limactl start

	# https://github.com/lima-vm/lima/blob/master/docs/multi-arch.md
	if $QEMU; then
		log_verbose "Installing cross architecture"
		lima sudo systemctl start containerd
		lima sudo nerdctl run --privileged --rm tonistiigi/binfmt --install all
		for arch in arm64 amd64; do
			lima nerdctl run --platform="$arch" --rm alpine uname -m
		done

		log_verbose "QEMU architectures supported..."
		if $VERBOSE; then
			lima ls -l "/proc/sys/fs/binfmt_misc/qemu*"
		fi

		# https://github.com/containerd/nerdctl/blob/master/docs/multi-platform.md
		log_verbose "cross platform push"
		log_verbose "lima nerdctl build --platform=amd64,arm64 -t richt/test ."
	fi
	if $VERBOSE; then
		lima uname -a
	fi
fi

# https://github.com/abiosoft/colima
#https://github.com/abiosoft/colima/issues/75
if $COLIMA; then
	# it is also the command line which we do
	package_install kubectl
	# note that docker has a collision it is a cask which we do not want
	# if you want Docker for mac then you need cask_install
	log_verbose "Installing command line docker"
	brew_install docker
	log_verbose "linking command line docker could overwrite Docker for Mac"
	brew link --overwrite docker
	log_verbose "docker or colima nerdctl to run containers"

	if ! $COLIMA_STABLE; then
		PACKAGE_FLAGS="--head"
	fi
	package_install $PACKAGE_FLAGS colima lima

	# the default
	log_verbose "colima works with docker ps"
	# --runtime docker is the default
	COLIMA_FLAGS=(--cpu 2 --memory 4 --disk 100)
	if $KUBERNETES; then
		COLIMA_FLAGS+=(--with-kubernetes)
	fi
	log_verbose "Starting colima with ${COLIMA_FLAGS[*]}"
	colima start "${COLIMA_FLAGS[@]}"

	if $VERBOSE; then
		log_verbose "colima works kubectl using containerd"
		colima start --runtime containerd --profile cd
		colima delete --profile cd
		log_verbose "cross architecture container for x86"
		# https://github.com/abiosoft/colima/blob/main/environment/vm.go
		colima start --runtime containerd --arch x86_64 --profile amd64
		colima delete --profile amd64
		log_verbose "cross architecture for M1"
		colima start --runtime containerd --arch aarch64 --profile arm64
		colima delete --profile arm64
		log_verbose "run with bigger machine"
		colima delete --profile large
		log_verbose "colima works with kubectl using docker"
		colima start --runtime docker --with-kubernetes --profile k8s --verbose
		colima delete --profile k8s
	fi

fi

# should be in .zprofile but put into .zshrc if zsh not used as login shell
if ! config_mark "$(config_profile_nonexportable_zsh)"; then
	if ! $LIMA; then
		log_verbose "lima code completion not working in zsh as of Dec 2021"
		config_add "$(config_profile_nonexportable_zsh)" <<-'EOF'
			command -v limactl >/dev/null && limactl completion zsh > "${fpath[1]}/_limactl"
		EOF
	fi
	if ! $COLIMA; then
		config_add "$(config_profile_nonexportable_zsh)" <<-'EOF'
			command -v colima >/dev/null && colima completion zsh > "${fpath[1]}/_colima"
		EOF
	fi
fi

if $PODMAN; then
	log_warning "As of Dec 2021 podman does not supported mounted volumes use colima instead"
	package_install podman
	podman machine init --cpu=4 --disk-size=100 --memory=4096
	podman machine start
	if $VERBOSE; then
		podman info
	fi

	# https://mohitgoyal.co/2021/04/26/create-kubernetes-clusters-with-kind-rootless-docker-and-rootless-podman/
	# https://kind.sigs.k8s.io/docs/user/rootless/
	# https://shipit.dev/posts/minikube-vs-kind-vs-k3s.html
	if ! command -v kind >/dev/null; then
		log_verbose "KinD for Kubernetes found"
		log_verbose "export KIND_EXPERIMENTAL_PROVIDER=podman to use Podman"
		if mac_is_arm; then
			log_warning "Podman does not run with Kind as of Dec 2021"
			# https://github.com/containers/podman/issues/11389
			# https://gist.github.com/kaaquist/dab64aeb52a815b935b11c86202761a3
			log_warning "Podman does not work with Docker Compose multiple containers"
		fi
	fi

	# https://docs.podman.io/en/latest/markdown/podman-completion.1.html
	# brew should already install bash completions for lima
	log_verbose "Adding bash completions"
	podman completion -f "/etc/bash_completion.d/podman" bash

	# if zsh is login shell can go into .zprofile but @richtong
	# uses it as non-login so put into .zshrc
	if ! config_mark "$(config_profile_nonexportable_zsh)"; then
		log_verbose "Adding zsh completions"
		config_add "$(config_profile_nonexportable_zsh)" <<-'EOF'
			command -v podman >/dev/null && podman completion -f"${fpath[1]}/_podman" zsh
		EOF
	fi

	if $QEMU; then
		log_verbose "Adding QEMU into container to run cross-platform images"
		# https://edofic.com/posts/2021-09-12-podman-m1-amd64/
		podman machine ssh <<-EOF
			sudo rpm-ostree install qemu-user-static
			sudo systemctl reboot
		EOF
	fi

	if $VERBOSE; then
		log_verbose "Try running Hello World"
		podman run --rm -it hello-world
	fi

	# https://davegallant.ca/blog/2021/10/11/replacing-docker-with-podman-on-macos-and-linux/
	# use docker compose with a podman pipe instead
	# this podman compose does not suppor --env-file
	#log_verbose "Install podman-compose"
	#pip_install podman-compose

fi
