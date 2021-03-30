#!/usr/bin/env bash
##
## Installs Kubernetes both the kubectl
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DOCKER="${DOCKER:-"false"}"
MINIKUBE="${MINIKUBE:-"false"}"
FORCE="${FORCE:-"false"}"
MICROK8S="${MICROK8S:-"false"}"
OPTIND=1
while getopts "hdvmuof" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install Kubernetes command line and then a k8s implementation
			flags: -d debug, -v verbose, -h help
				-f force installation (default: $FORCE)
				-m minikube (default: $MINIKUBE)
				-u MicroK8s current hangs on MacOS (default: $MICROK8S)
				-o Docker has a single cluster version (default: $DOCKER)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	f)
		FORCE=true
		;;
	m)
		MINIKUBE=true
		;;
	u)
		MICROK8S=true
		;;
	o)
		DOCKER=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND - 1))
source_lib lib-util.sh lib-install.sh lib-config.sh
KUBE_VERSION="${KUBE_RELEASE:-"$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"}"
KUBE_DEST="${KUBE_DEST:-"/usr/local/bin/kubectl"}"
KUBE_URL="${KUBE_URL:-https://storage.googleapis.com/kubernetes-release/release/$KUBE_VERSION/bin/linux/amd64/kubectl}"

#if ! $FORCE && command -v kubectl; then
#log_exit "already installed"
#fi

if in_os mac; then
	log_verbose "Installing on MacOS"
	# also need sponge in moreutils to prevent redirect problems
	package_install kubernetes-cli krew helm

	log_verbose "closing up secretes in .kube/config"
	mkdir -p "$HOME/.kube"
	chmod 700 "$HOME/.kube"
	chmod 600 "$HOME/.kube/config"

	log_verbose "configring helm"
	# stable is deprecated use artifactory hub to find the right repos
	#helm repo add stable https://charts.helm.sh/stable
	helm repo add bitnami https://charts.bitnami.com/bitnami
	log_verbose "to use helm install rich-wp bitnami/wordpress"

	log_verbose "installing bash autocomplete and krew into $(config_profile)"
	if ! config_mark; then
		# https://github.com/corneliusweig/konfig
		config_add <<-'EOF'
			[[ $PATH =~ .krew/bin ]] || export PATH="$PATH:$HOME/.krew/bin"
			# shellcheck disable=SC1090
			source <(kubectl completion bash)
		EOF
	fi
	source_profile
	hash -r
	# https://github.com/corneliusweig/konfig
	# used by microk8s to merge its config file
	kubectl krew install konfig
	log_warning "docker has a single note kubernetes"
	# https://ubuntu.com/blog/kubernetes-on-mac-how-to-set-up

	if $DOCKER; then
		log_verbose "docker has a 1 node cluster"
		"$BIN_DIR/install-docker.sh"
	fi
	if $MINIKUBE; then
		log_verbose "minikube deprecated for microk8s"
		"$BIN_DIR/install-minikube.sh"
	fi
	if $MICROK8S; then
		log_verbose "Install MicroK8s"
		tap_install ubuntu/microk8s
		package_install microk8s multipass
		hash -r
		microk8s install
		# https://ubuntu.com/tutorials/install-microk8s-on-mac-os#4-wait-for-microk8s-to-start
		log_verbose "microk8s installed waiting for it to start"
		if ! microk8s --help >/dev/null; then
			# https://github.com/canonical-web-and-design/microk8s.io/issues/239
			log_verbose "microk8s failed delete vm and retry"
			multipass delete microk8s-vm
			multipass purge
			microk8s install
		fi
		microk8s status --wait-ready
		if $VERBOSE; then
			microk8s kubectl get nodes
			microk8s kubectl get services
		fi
		microk8s enable dashboard dns storage
		log_verbose "run microk8s dashboard-proxy to see dashboard"
		log_verbose "to turn on and off use microk8s stop and microk8s start"
		log_verbose "enabling the system kubectl to see microk8s"
		# only works with v3 of y1, can't figure out how to make it work with v4
		# microk8s config | yq m -i -a append "$HOME/.kube/config" -
		TEMP=$(mktemp)
		microk8s config >"$TEMP"
		# need sponge so that the redirect doesn't kill the original file
		# https://github.com/corneliusweig/konfig
		kubectl konfig import --save "$TEMP"
		rm "$TEMP"
		log_verbose "to use the microk8s cluster run kubectl config use-contest microk8s"
		# https://microk8s.io/docs/addon-kubeflow
		log_verbose "workaround for kubeflow adding user groups"
		# note we need an eval to delay finding these shell variable in the VM
		# because microk8s does sudo for everything and kubeflow does not want
		# that https://github.com/ubuntu/microk8s/issues/1763#issuecomment-731999949
		# shellcheck disable=SC2016
		log_verbose "running usermod"
		# shellcheck disable=SC2016
		if ! multipass exec microk8s-vm -- eval 'sudo usermod -a -G microk8s $USER'; then
			log_error 2 "sudo usermod failed"
		fi

		# shellcheck disable=SC2016
		log_verbose "running chown"
		# shellcheck disable=SC2016
		if ! multipass exec microk8s-vm -- eval 'sudo chown -f -R $USER $HOME/.kube'; then
			log_error 3 "sudo chown failed"
		fi

		log_verbose "running kubeflow"
		if ! multipass exec microk8s-vm -- microk8s enable kubeflow --ignore-min-mem --bundle lite; then
			log_error 4 "enable kubeflow failed"
		fi

	fi
else
	log_verbose "curl from $KUBE_URL"
	sudo curl -L "$KUBE_URL" -o "$KUBE_DEST"
	sudo chmod +x "$KUBE_DEST"
fi
