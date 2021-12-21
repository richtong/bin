#!/usr/bin/env bash
##
## Install Podman
## https://podman.io/getting-started/installation
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
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs 1Password
			    usage: $SCRIPTNAME [ flags ]
				flags: -d debug (not functional use bashdb), -v verbose, -h help"
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
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh

brew install podman
podman machine init
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

if ! config_mark; then
	config_add <<-'EOF'
		podman completion -f "/etc/bash_compoletion.d/podmash" bash
	EOF
fi
if ! config_mark "$HOME/.zshrc"; then
	log_verbose "Manually add completion no OMZ available"
	config_add <<-'EOF'
		podman completion -f"${fpath[1]}/_podman" zsh
	EOF
fi
