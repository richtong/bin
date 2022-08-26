#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
# Need to use /usr/bin/env for Mac OS to get the correct bash
#
##install docker
## Uses the wget method the first time for docker
## Also install docker-machine
## After that you can just sudo apt-get install docker-engine
## Assumes you are running under wsbash so environment is set
##@author Rich Tong
##
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
DOCKER_CONTENT_TRUST="${DOCKER_CONTENT_TRUST:-false}"
DOCKER_TRUST_PRIVATE="${DOCKER_TRUST_PRIVATE:-"$SCRIPT_DIR/ssh/docker"}"
DOCKER_VERSION="${DOCKER_VERSION:-20.10.17}"
# Do not make too high as this will fail the minimum version needed test
# Also this is not the Mac Docker App version, it is engine version
DOCKER_INSTALL_EDGE_VERSION="${DOCKER_INSTALL_EDGE_VERSION:-20.10.12}"
DOCKER_MACHINE_VERSION="${DOCKER_MACHINE_VERSION:-0.16.1}"
DOCKER_COMPOSE_VERSION="${DOCKER_COMPOSE_VERSION:-1.26.2}"
BUILDKIT_STEP_LOG_MAX_SIZE="${BUILDKIT_STEP_LOG_MAX_SIZE:-50000000}"
INSTALL_EDGE="${INSTALL_EDGE:-false}"

FORCE="${FORCE:-false}"
OPTIND=1
while getopts "hdvctr:m:o:fns:l:i:" opt; do
	case "$opt" in
	h)
		cat <<EOF
$SCRIPTNAME: installs docker and other support programs like docker-machine and docker-compose

flags: -h help
       -d $(! $DEBUGGING || echo "no ")debugging
       -v $(! $VERBOSE || echo "not ")verbose
	   -c $(! $DOCKER_CONTENT_TRUST || echo "do not ") enable content trust
	   -f $(! $FORCE || echo "do not ")force redownload of installation


       -l buildx log size (default: $BUILDKIT_STEP_LOG_MAX_SIZE)
	   -i use docker image registry (default: $DOCKER_REGISTRY)

	   deprecated:
       -t your private trust key directory (default: $DOCKER_TRUST_PRIVATE)
       -r docker version to install (default: $DOCKER_VERSION)
          note this is the docker engine version not the Mac App version
       -m docker machine version (default: $DOCKER_MACHINE_VERSION)
       -o docker compose version (default: $DOCKER_COMPOSE_VERSION)
	   -n install edge release now switch in main (default: $INSTALL_EDGE)
	   -s docker edge version minimum (default: $DOCKER_INSTALL_EDGE_VERSION)
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
	l)
		BUILDKIT_STEP_LOG_MAX_SIZE="$OPTARG"
		;;
	i)
		DOCKER_REGISTRY="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	c)
		DOCKER_CONTENT_TRUST="$($DOCKER_CONTENT_TRUST && echo false || echo true)"
		;;
	t)
		DOCKER_TRUST_PRIVATE="$OPTARG"
		;;
	r)
		DOCKER_VERSION="$OPTARG"
		;;
	m)
		DOCKER_MACHINE_VERSION="$OPTARG"
		;;
	o)
		DOCKER_COMPOSE_VERSION="$OPTARG"
		;;
	n)
		INSTALL_EDGE="$($INSTALL_EDGE && echo false || echo true)"
		;;
	s)
		DOCKER_INSTALL_EDGE_VERSION="$OPTARG"
		;;
	*)
		log_warning "no $opt flag"
		;;
	esac
done
# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-docker.sh lib-install.sh lib-mac.sh lib-version-compare.sh lib-config.sh
DEBUGGING=${DEBUGGING:=false}
DOCKER_MACHINE=${DOCKER_MACHINE:="https://github.com/docker/machine/releases/download/v$DOCKER_MACHINE_VERSION/docker-machine-$(uname -s)-$(uname -m)"}
DOCKER_COMPOSE=${DOCKER_COMPOSE:="https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)"}

log_verbose checking if we are already in docker
if in_os docker; then
	log_exit "already in docker"
fi

version_needed="$DOCKER_VERSION"
if $INSTALL_EDGE; then
	version_needed="$DOCKER_INSTALL_EDGE_VERSION"
fi
log_verbose "check for docker looking for version $version_needed"

if ! $FORCE && command -v docker &>/dev/null; then
	INSTALLED_DOCKER="$(version_extract "$(docker -v)")"
	if vergte "$INSTALLED_DOCKER" "$version_needed"; then
		log_warning "docker installed $INSTALLED_DOCKER greater or equal to desired $version_needed"
	fi
fi

# We check for variables with the conditional assignment is the variable
# is not set, then it is replaced by a null string and doesn't trip set -u
# ${var-} means if $var is unset then replace it with a null string
# https://stackoverflow.com/questions/7832080/test-if-a-variable-is-set-in-bash-when-using-set-o-nounset
# http://stackoverflow.com/questions/12983137/how-do-detect-if-travis-ci-or-not
if [[ -v TRAVIS ]]; then
	log_message "in Travis CI setting services : docker in .travis.yml"
	# note that lib-install.sh/package-install.sh will not work we need to
	# upgrade
	#package_install docker-engine
	# http://blog.awolski.com/upgrade-docker-on-travis-ci/
	# You will get a configuration error so you need to do this manually and
	# force it as the installer does not want to overwrite a configuration file
	sudo apt-get install -o Dpkg::Options::="--force-confold" --force-yes -y docker-engine
	exit
fi

if [[ -v CIRCLECI ]]; then
	log_exit "Circle CI already has a hacked version of docker"
fi

# http://blog.docker.com/2015/07/new-apt-and-yum-repos/#more-6860
if in_os mac; then
	log_verbose install with brew cask
	if $INSTALL_EDGE; then
		# https://github.com/caskroom/homebrew-versions
		# log_verbose installing alternative beta and edge versions for tap
		log_warning "Edge now included in mainline docker ignore edge"
	#    tap_install homebrew/cask-versions
	#    # So swap docker_edge for docker if installed
	#    log_verbose install docker-edge
	#    cask_swap docker-edge docker
	#else
	#    log_verbose install docker and uninstall docker-edge if needed
	#    cask_swap docker docker-edge
	fi
	cask_install docker
	log_warning "docker now installed by homebrew open it up and fill it in before continuing"
	log_warning "it is best to login from the Docker.app"
	open -a Docker.app
	util_press_key

	if ! command -v docker || ! vergte "$(version_extract "$(docker -v)")" "$version_needed"; then
		log_verbose the installation failed using brew so try the curl
		# Note this no longer uninstalls from macports as we do not use it
		# log_verbose uninstall MacPorts versions if they are present
		# package_uninstall docker-machine docker-compose docker
		log_verbose install direction from docker.com
		download_url_open "https://download.docker.com/mac/stable/Docker.dmg"
		find_in_volume_copy_then_detach Docker.app
	fi
	#log_warning "this installs Docker for Mac but if you have an old Mac run"
	#log_warning "run $WS_DIR/bin/install-docker-toolbox.sh"

else
	log_verbose "Non-Mac installation"
	# log_verbose docker-py needed for wscons in all versions of linux
	# pip_install docker-py
	PACKAGES=(
		apt-transport-https
		ca-certificates
		curl
		gnupg
		lsb-release
	)
	if in_wsl; then
		log_exit "WSL does not need docker install in Windows"
	fi
	if in_linux debian; then
		log_verbose "installnig for debian"
		# https://docs.docker.com/engine/installation/linux/docker-ce/debian/#install-docker-ce
		package_install "${PACKAGES[@]}"
		curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add
		# need |& because stderr warns not to pipe output
		# need the asterisks because spaces vary in the string
		if ! apt-key list 0EBFCD88 |&
			grep -q '9DC8 *5822 *9FC7 *DD38 *854A *E2D8 *8D81 *803C *0EBF *CD88'; then
			log_error 2 "bad apt-key fingerprint"
		fi
		repository_install "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"
		package_install docker-ce
	elif in_linux ubuntu; then
		# https://phoenixnap.com/kb/install-docker-on-ubuntu-20-04
		# https://docs.docker.com/engine/install/ubuntu/
		log_verbose "trying to install docker for ubuntu with brew"
		if ! package_install docker; then
			log_verbose "docker.io package failed so install pieces"
			package_install "${PACKAGES[@]}"
			curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
				sudo gpg --deearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
			sudo add-apt-repository \
				"deb [arch=amd64] signed-by /usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
			sudo apt-get update
			sudo apt-get install docker-ce docker-ce-cli containerd.io

			if $VERBOSE; then
				log_verbose "docker versions available"
				apt-cache madison docker-ce
			fi
		fi

		if ! command -v docker || ! docker -v | grep "$version_needed"; then
			# We could have old docker components from ubuntu oritented installs
			# It is ok if we do not find it
			sudo apt-get purge -y lxc-docker* || true
		fi

		# the dangerous version do not install opaque scripts
		# curl -fsSL  https://get.docker.com/ | sh
		service_start docker

	fi

	"$SCRIPT_DIR/install-node.sh"
	NPM_PACKAGES=(dockerfilelint)
	#shellcheck disable=SC2086
	npm_install -g "${NPM_PACKAGES[@]}"
	log_verbose "turn off sudo checks they do not work for sudo group"
	if ! config_mark "$HOME/.dockerfilelintrc"; then
		config_add "$HOME/.dockerfilelintrc" <<-EOF
			rules:
			  disable_sudo: off
		EOF
	fi

	# does not seem to be supported
	log_verbose "Install hub-tools for Docker Hub CLI login with hub-tool login"
	#GO111MODULE=on go get github.com/docker/hub-tool
	go install github.com/docker/hub-tool@latest

	# https://docs.docker.com/security/trust/content_trust/
	if $DOCKER_CONTENT_TRUST && ! grep "$DOCKER_CONTENT_TRUST" ~/.bashrc; then
		echo "# Added by $SCRIPTNAME on $(date)" >>"$HOME/.bashrc"
		echo "export DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST" >>"$HOME/.bashrc"
	fi

	install_docker_module() {
		if [[ $# -lt 2 ]]; then return 1; fi
		local tool="$1"
		local version="$2"
		local url="$3"
		# only download if the tool does not exist or has a lower version number than desired
		if ! command -v "$tool" || verlt "$(version_extract "$("$tool" version)")" "$version"; then
			# use tee because sudo does not work on redirection
			curl -L "$url" | sudo tee "/usr/local/bin/$tool" >/dev/null
			sudo chmod +x "/usr/local/bin/$tool"
		fi
	}

	log_verbose "docker machine and compose are deprecated"
	log_verbose "Linux packages are out of date so direct install"
	#install_docker_module docker-machine "$DOCKER_MACHINE_VERSION" "$DOCKER_MACHINE"
	#install_docker_module docker-compose "$DOCKER_COMPOSE_VERSION" "$DOCKER_COMPOSE"

	# If this isn't your first docker installation, you need to provide your super
	# secret signing keys
	if [ -d "$DOCKER_TRUST_PRIVATE" ]; then
		mkdir -p ~/.docker/trust/private
		rsync -a "$DOCKER_TRUST_PRIVATE/*" ~/.docker/trust/private/
	fi

	# If a non-root users, add to the docker group
	log_warning "docker is sudoless which is a security risk but convenient"
	log_warning "If you want to be safer run but you always need to sudo docker but certain command break"
	log_warning "sudo deluser $USER docker"
	log_warning "note that this is superceded if you are a using iamuser sync and are in the iamusers group"
	sudo usermod -aG docker "$USER"

	log_verbose "see if you can use docker if not see if it is running and see if you are in the right group"

	if ! docker_available; then
		log_warning "If you want to test right away use newgrp docker in an interactive"
		log_warning "shell and re-run the script"
		log_warning "On Ubuntu, logout and logon again to get new group"
		log_warning "On Debian, reboot to get the new group"
		log_warning "If you want docker managed by IAM user usermod -aG $USER iamusers"
		log_warning "and this will manage docker access through /etc/opt/tongfamily"
		log_warning "Make sure to run a docker login to pull private images"
		log_error 1 "docker installed but you are not in the docker group"
	fi
fi

log_verbose "Create dedicated docker buildx with large log size"
docker buildx create --name docker-buildx --use --driver-opt \
	env.BUILDKIT_STEP_LOG_MAX_SIZE="${BUILDKIT_STEP_LOG_MAX_SIZE:-10000000}"
