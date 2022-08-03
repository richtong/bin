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

COLIMA="${COLIMA:-false}"
DOCKER="${DOCKER:-false}"
FORCE="${FORCE:-false}"
K3AI="${K3AI:-false}"
K3S="${K3S:-false}"
KIND="${KIND:-false}"
KUBEFLOW="${KUBEFLOW:-false}"
MICROK8S="${MICROK8S:-false}"
MINIKUBE="${MINIKUBE:-false}"
MULTIPASS="${MULTIPASS:-false}"

OPTIND=1
while getopts "hdvmuiofkcbsa" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install Kubernetes command line and then a k8s implementation
			flags: -h help
			   -d $(! $DEBUGGING || echo "no ")debugging
			   -v $(! $VERBOSE || echo "not ")verbose
				-f force installation (default: $FORCE)
			   -d $(! $DEBUGGING || echo "no ")debugging
				-c $(! $COLIMA || echo "No ")Install Colima with Kubernetes support
				-o $(! $DOCKER || echo "No ")Install Docker with a single cluster version
				-m $(! $MINIKUBE || echo "No ")Install minikube a single node Kubernetes
				-k $(! $KIND || echo "No ")Install a lightweight KIND
				-s $(! $K3S || echo "No ")Install a lightweight Rancher K3S
				-a $(! $K3AI || echo "No ")Install a K3S tunes for AI as K3AI
				-u $(! $MULTIPASS || echo "No ")Install Multipass enables Canonical Microk8s from inside VM
				-i $(! $MICROK8S || echo "No ")Install microK8s using Multipass
				-b $(! $KUBEFLOW || echo "No ")Install kubeflow
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
		FORCE="$($FORCE && echo false || echo true)"
		;;
	c)
		COLIMA="$($COLIMA && echo false || echo true)"
		;;
	m)
		MINIKUBE="$($MINIKUBE && echo false || echo true)"
		;;
	i)
		MICROK8S="$($MICROK8S && echo false || echo true)"
		;;
	u)
		MULTIPASS="$($MULTIPASS && echo false || echo true)"
		;;
	k)
		KIND="$($KIND && echo false || echo true)"
		;;
	o)
		DOCKER="$($DOCKER && echo false || echo true)"
		;;
	b)
		KUBEFLOW="$($KUBEFLOW && echo false || echo true)"
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

# https://www.kubeflow.org/docs/components/pipelines/installation/localcluster-deployment/
if $KIND; then
	log_verbose "Install KinD"
	brew_install kind
	if ! config_mark "$(config_profile_nonexportable)"; then
		config_add "$(config_profile_nonexportable)" <<-'EOF'
			command -v kind || source kind completion bash
		EOF
	fi
	if ! kind get clusters | grep -q kind; then
		log_verbose "No Kind cluster creating it"
		kind create cluster
	fi
fi
if $K3S; then
	log_verbose "Install Redhat Rancher K3S"
	sudo k3 server
	if command -v nvidia-smi &>/dev/null; then
		curl -sFL https://get.k3ai.in | bash -s -- --gpu --plugin_kfpipelines
	else
		curl -sFL https://get.k3ai.in | bash -s -- --cpu --plugin_kfpipelines
	fi
fi
if $K3AI; then
	log_verbose "Install K3AI using Rancher K3S"
	curl -sFL "https://get.k3ai.in" | sh -
	log_verbose "start with k3ai up"
fi
if $KUBEFLOW && ($KIND || $K3S || $K3AI); then
	log_verbose "Running Argo against KIND, K3S or K3AI"
	export PIPELINE_VERSION=1.8.3
	kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/cluster-scoped-resources?ref=$PIPELINE_VERSION"
	kubectl wait --for condition=established --timeout=60s crd/applications.app.k8s.io
	kubectl apply -k "github.com/kubeflow/pipelines/manifests/kustomize/env/platform-agnostic-pns?ref=$PIPELINE_VERSION"
	kubectl port-forward -n kubeflow svc/ml-pipeline-ui 8080:80
	log_verbose "http://localhost:8080 for Kubeflow Pipeline"
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
			microk8s status
		fi
		log_verbose "to turn on and off use microk8s stop and microk8s start"
		log_verbose "to enter multipass host run multipass shell microk8s-vm"

		# https://microk8s.io/docs/working-with-kubectl
		# for v3 or earlier: icrok8s config | yq m -i -a append "$HOME/.kube/config" -
		if $VERBOSE; then microk8s config; fi
		TEMP=$(mktemp)
		microk8s config >"$TEMP"
		# need sponge so that the redirect doesn't kill the original file
		# https://github.com/corneliusweig/konfig
		kubectl konfig import --save "$TEMP"
		log_verbose "Microk8s cluster can be accessed as kubectl config set-cluster microk8s-cluster"
		rm "$TEMP"
		log_verbose "changing kubectl context to microk8s to use kubectl"
		log_verbose "access clust with kubectl -n kube-system get pods"
		kubectl config set-context microk8s
		if $VERBOSE; then
			kubectl get nodes
			kubectl -n kube-system get pods
		fi

		log_verbose "run microk8s dashboard-proxy to see dashboard"
		# https://microk8s.io/docs/addon-dashboard
		microk8s enable dashboard
		log_verbose "Token for Dashboard..."
		# with the code above to integrate into system kubectl do not need this
		#multipass exec microk8s-vm -- sudo /snap/bin/microk8s kubectl \
		#    -n kube-system \
		#    describe secret \
		#    "$(multipass exec microk8s-vm -- \
		#        sudo /snap/bin/microk8s kubectl -n kube-system get secrets |
		#        grep default-token | cut -d " " -f1)"
		# alternative way not reaching deep into multipass and use system
		# kubectl
		kubectl -n kube-system describe secrets \
			"$(kubectl -n kube-system get secrets | grep default-token | cut -d " " -f 1)"

		log_verbose "Port forward from multipass to Mac in background"
		kubectl -n kube-system port-forward \
			service/kubernetes-dashboard 10443:443 \
			--address 0.0.0.0 &
		IP=$(multipass info microk8s-vm | grep IPv4 | awk '{print $2}')
		log_verbose "Cannot Access dashboard at https://$IP:10443 as of August 2022"

		if $KUBEFLOW; then
			log_verbose "Kubeflow on MacOS install"
			# https://charmed-kubeflow.io/docs/quickstart trying Linux on Mac
			# insturction
			# dns installed by default
			# lbmetal not on machine
			# kubeflow as of August 2002 not available for 1.22
			# https://microk8s.io/docs/install-alternatives
			log_verbose "Install ingress service"
			microk8s enable istio
			log_verbose "Add juju controller should already exist"
			microk8s juju bootstrap microk8s
			log_verbose "GEtting the application model kubeflow"
			microk8s juju add-model kubeflow
			log_verbose "Install kubeflow lite"
			microk8s juju deploy kubeflow-lite trust
			log_verbose "Simple authentication admin/admin"
			microk8s juju dex-auth static-username=admin
			microk8s juju dex-auth static-password=admin

		fi

	elif in_os linux; then
		log_verbose "Ensable dashboard on Linux"
		microk8s enable dashboard
		microk8s kubectl create token default
		microk8s kubectl port-forard -n kube-system service/kubernetes-dashboard 10443:433
		log_verbose "Access dashboard at https:localhost:10443"
		# https://charmed-kubeflow.io/docs/quickstart
		# https://charmed-kubeflow.io/docs/install
		log_verbose "Install Kubeflow 1.4 not compatible with 1.22"
		if $KUBEFLOW; then
			log_verbose "install kubeflow on linux on microk8s"
			snap_install --classic --channel=1.21/stable microk8s
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
