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
QEMU="${QEMU:-false}"
while getopts "hdvq" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Podman and Lima
				Podman is Redhat's CLI replacement for docker
				Lima is an open source replacement for a linux VM with full
				sharing to Linux, like Linux Subsystem for Mac (ala WSL)

			    usage: $SCRIPTNAME [ flags ]
				flags: -d debug (not functional use bashdb), -v verbose, -h help"
					   -q run QEMU emulation for multiple architecture
					   (default: $QEMU)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		# add the -v which works for many commands
		export FLAGS+=" -v "
		;;
	q)
		QEMU=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh

brew install podman lima
podman machine init --cpu=4 --disk-size=100 --memory=4096
podman machine start

log_verbose "On M1 Mac this fails with sshfs not loaded"
limactl start

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
if ! config_mark; then
	config_add <<-'EOF'
		podman completion -f "/etc/bash_completion.d/podmank:w " bash
	EOF
fi

if ! config_mark "$(config_profile_zsh)"; then
	log_verbose "Manually add completion no OMZ available"
	config_add <<-'EOF'
		podman completion -f"${fpath[1]}/_podman" zsh
		limactl completion zsh
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
