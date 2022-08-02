#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Installs Kubernetes both the kubectl
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

DOCKER="${DOCKER:-false}"
MINIKUBE="${MINIKUBE:-false}"
FORCE="${FORCE:-false}"
MICROK8S="${MICROK8S:-true}"
DEPRECATED_KUBEFLOW="${DEPRECATED_KUBEFLOW:-false}"
KIND="${KIND:-false}"
MULTIPASS="${MULTIPASS:-false}"
COLIMA="${COLIMA:-false}"
KUBEFLOW="${KUBEFLOW:-false}"

OPTIND=1
while getopts "hdvmuiofkcb" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install Kubernetes command line and then a k8s implementation
			flags: -h help
			   -d $(! $DEBUGGING || echo "no ")debugging
			   -v $(! $VERBOSE || echo "not ")verbose
				-f force installation (default: $FORCE)
				-c Install Colima with Kubernetes support (default: $COLIMA)
				-o Install Docker with a single cluster version (default: $DOCKER)
				-m Install minikube a single node Kubernetes (default: $MINIKUBE)
				-k Install a lightweight minikube (default $KIND)
				-u Install Multipass enables Microk8s from inside VM (default: $MULTIPASS)
				-i Install microK8s using Multipass with (default: $MICROK8S)
				-b Install kubeflow using Juju on Ubuntu with microk8s (default: $KUBEFLOW)
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	f)
		FORCE=true
		;;
	c)
		COLIMA=true
		;;
	m)
		MINIKUBE=true
		;;
	i)
		MICROK8S=true
		;;
	b)
		DEPRECATED_KUBEFLOW=true
		;;
	u)
		MULTIPASS=false
		;;
	k)
		KIND=true
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
if ! in_os mac; then
	log_exit "Mac Only"
fi

# krew - kubectl plugin manager
PACKAGES+=(
	kubernetes-cli
	helm
	krew
)

log_verbose "Base installation of tools ${PACKAGES[*]}"
# also need sponge in moreutils to prevent redirect problems

package_install "${PACKAGES[@]}"

log_verbose "closing up secrets in .kube/config"
mkdir -p "$HOME/.kube"
chmod 700 "$HOME/.kube"
touch "$HOME/.kube/config"
chmod 600 "$HOME/.kube/config"

log_verbose "configure helm"

#helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
log_verbose "to use helm install rich-wp bitnami/wordpress"

# https://github.com/corneliusweig/konfig
# completions can go into the profile
# this must in /bin/sh format for .profile
#if command -v helm >/dev/null; then source <(helm completion bash); fi
#if command -v kubectl > /dev/null; then source <(kubectl completion bash); fi
if ! config_mark; then
	log_verbose "adding completions"
	config_add <<-'EOF'
		# shellcheck disable=SC1090
				echo "$PATH" | grep ".krew/bin" || export PATH="$HOME/.krew/bin:$PATH"
	EOF
fi

if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-'EOF'
		# shellcheck disable=SC1090
		if command -v helm >/dev/null; then eval "$(helm completion bash)"; fi
		# shellcheck disable=SC1090
		if command -v kubectl > /dev/null; then eval "$(kubectl completion bash)"; fi
	EOF
fi

log_verbose "Pick up profile changes"
source_profile

# https://github.com/corneliusweig/konfig
# used by microk8s to merge its config file
kubectl krew install konfig
log_warning "docker has a single note kubernetes"
# https://ubuntu.com/blog/kubernetes-on-mac-how-to-set-up

log_verbose "Installing virtual environments"

if $COLIMA; then
	log_verbose "Install Colima warning this installs a colima.yaml in $CWD"
	"$BIN_DIR/install-docker-alternative.sh" -k
fi

if $KIND; then
	log_verbose "Install KinD"
	brew install kind
fi

if $DOCKER; then
	log_verbose "docker has a 1 node cluster"
	"$BIN_DIR/install-docker.sh"
fi

if $MINIKUBE; then
	log_verbose "minikube deprecated for microk8s"
	"$BIN_DIR/install-minikube.sh"
fi

if $MICROK8S; then
	if in_os mac; then
		# https://ubuntu.com/tutorials/installing-microk8s-on-apple-m1-silicon#1-installation
		log_verbose "Install MicroK8s"
		tap_install ubuntu/microk8s
		package_install microk8s multipass
		hash -r
		log_verbose "microk8s installed waiting for it to start"
		microk8s install
		# https://ubuntu.com/tutorials/install-microk8s-on-mac-os#4-wait-for-microk8s-to-start
		if ! microk8s --help >/dev/null; then
			# https://github.com/canonical-web-and-design/microk8s.io/issues/239
			log_verbose "microk8s failed delete vm and retry"
			microk8s uninstall
			multipass delete microk8s-vm
			multipass purge
			if ! microk8s install; then
				log_error 2 "microk8s installation failed maybe internet issues, remove vpns and retry"
			fi
		fi
		microk8s status --wait-ready
		if $VERBOSE; then
			microk8s kubectl get nodes
			microk8s kubectl get services
		fi
		microk8s enable dashboard dns storage
		log_verbose "run microk8s dashboard-proxy to see dashboard"
		log_verbose "run microk8s kubectl to use its own kubectl"
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
	elif in_os linux; then
		# https://charmed-kubeflow.io/docs/install
		#https://charmed-kubeflow.io/docs/install https://charmed-kubeflow.io/docs/quickstart
		log_verbose "Install Kubeflow 1.4 not compatible with 1.22"
		if $KUBEFLOW; then
			log_verbose "install kubeflow on linux on microk8s"
			snap_insdall --classic --channel=1.21/stable microk8s
			sudo usermod -a -G microk8S "$USER"
			newgrp microk8s
			sudo chown -f -R "$USER" "$HOME/.kube"
			# metal load balancer does not work on MacOS multipass
			microk8s enable dns storage ingress
			microk8s enable metal-lb:10.64.140.43-10.64.140.49
			microk8s status --wait-ready
			# https://canonical.com/blog/learning-to-speak-juju
			log_verbose "Install juju to manage clouds in aws, azure, localhost, google"
			snap_install juju
			juju bootstrap microk8s
			juju add-model kubeflow
			juju deploy kubeflow-lite --trust

			# Not clear what the url is
			# on mac since there is a proxy
			juju config dex-auth public-url=http://192.168.41.1
			juju config oidc-auth public-url=http://192.168.41.1
			juju config dex-auth satic-username=admin
			juju config dex-auth static-password=admin
			log_verbose "dex username and password admin/admin"
		elif in_os macos; then
			kkk
		fi
	fi

	# https://charmed-kubeflow.io/docs/quickstart as of July 2022
	if $DEPRECATED_KUBEFLOW; then
		# https://github.com/canonical/microk8s/issues/1763#issuecomment-731999949
		log_verbose "As of April 2021 this does not work"
		# https://microk8s.io/docs/addon-kubeflow deprecated
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
		log_verbose "restart microk8s-vm"
		if ! multipass restart microk8s-vm; then
			log_error 5 "could not restart microk8s"
		fi
		log_verbose "running kubeflow"
		if ! multipass exec microk8s-vm -- microk8s enable kubeflow --ignore-min-mem --bundle lite; then
			log_error 4 "enable kubeflow failed"
		fi
		# https://ubuntu.com/tutorials/install-microk8s-on-mac-os?_ga=2.190792939.1724531887.1619986586-1495806297.1619986586#6-deploy-an-app
		log_verbose "Running demonstration apps at kubernetes bootcamp"
		if $VERBOSE; then
			microk8s kubectl create deployment kubernetes-bootcamp --image=gcr.io/google-samples/kubernetes-bootcamp:v1
		fi
		log_verbose "wait a few minutes then run microk8s get pods and microk8s stop when done"
	fi
fi

# https://www.techrepublic.com/article/how-to-quickly-spin-up-microk8s-with-multipass/
if $MULTIPASS; then
	log_verbose "do not use microk8s but install directly into multipass"
	package_install multipass

	if multipass info microk8s-vm; then
		multipass stop microk8s-vm
		multipass delete microk8s-vm
		multipass purge
	fi

	multipass launch --name microk8s-vm --mem 3G
	multipass exec microk8s-vm -- sudo snap install microk8s --classic
	multipass exec microk8s-vm -- sudo iptables -P FORWARD ACCEPT
	# note the shell escaping does not work properly without bash -c
	# shellcheck disable=SC2016
	multipass exec microk8s-vm -- bash -c 'sudo usermod -aG microk8s $USER'
	# shellcheck disable=SC2016
	multipass exec microk8s-vm -- bash -c 'sudo chown -f -R $USER $HOME/.kube'

	if $VERBOSE; then
		# https://www.kubeflow.org/docs/distributions/microk8s/kubeflow-on-microk8s/
		log_verbose "test with nginx"
		multipass exec microk8s-vm -- microk8s kubectl run nginx --image=nginx:alpine --replicas=2 --port=80
		multipass exec microk8s-vm -- microk8s kubectl get pod
		log_verbose "enable kubeflow ignoring 8GB minimum memory"
		multipass exec microk8s-vm -- microk8s enable kubeflow --ignore-min-mem
		multipass list | grep microk8s-vm
		# https://stackoverflow.com/questions/18592173/select-objects-based-on-value-of-variable-in-object-using-jq
		ip=$(multipass list --format=json | jq '.list[] | select(.name=="microk8s-vm")| .ipv4[0]')
		# https://richardkmiller.com/925/script-to-enabledisable-socks-proxy-on-mac-os-x
		networksetup -setsocksfirewallproxy Wi-Fi 127.0.0.1 9999
		networksetup -setsocksfirewallproxy Ethernet 127.0.0.1 9999
		networksetup -setsocksfirewallproxystate Wi-Fi on
		networksetup -setsocksfirewallproxystate Ethernet on
		log_warning "point the socks proxy to the multipass vm"
		log_verbose "ssh -D9999 multipass@$ip"
	fi

fi
