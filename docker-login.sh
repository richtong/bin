#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
##install and login docker
## Uses the wget method the first time for docker
## After that you can just sudo apt-get install docker-engine
## https://stackoverflow.com/questions/69961611/how-can-i-login-to-multiple-docker-registries-at-same-time
##
## Note that we no longer need email as part of the
## login as of July 2017
##@author Rich Tong
##
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"

OPTIND=1

USE_SECRET_FILE="${USE_SECRET_FILE:-false}"
DOCKER_SECRET_FILE="${DOCKER_SECRET_FILE:-"$HOME/.ssh/$DOCKER_REGISTRY.pat"}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-""}"

LOGIN_ALL="${LOGIN_ALL:-true}"
DOCKER_USER="${DOCKER_USER:-richt}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io}"
DOCKER_TOKEN_URI="${DOCKER_TOKEN_URI:-"op://Private/Docker Container Registry - $DOCKER_USER/token"}"

GITHUB_USER="${GITHUB_USER:-richtong}"
GITHUB_REGISTRY="${GITHUB_REGISTRY:-ghcr.io}"
GITHUB_TOKEN_URI="${GITHUB_TOKEN_URI:-"op://Private/GitHub Container Registry - $REPO_USER/token"}"

GOOGLE_CONTAINER_REGISTRY="${GOOGLE_CONTAINER_REGISTRY:-gcr.io}"


FORCE=false
while getopts "hdv1fl:m:r:st:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: logon to docker container registries using 1Password

				logs in to all registries:
				docker-login.sh -a
				
				equivalent to:
				docker-login.sh -r gcr.io
				docker-login.sh -r ghcr.io -u $REPO_USER -t "$GITHUB_TOKEN_URI"
				docker-login.sh -r docker.io -u $DOCKER_USER -t "$DOCKER_TOKEN_URI"

			flags: -d debug, -h help -v verbose
			       -f force a new login even if one already exists (default $FORCE)

				   -r container registry name (default: $DOCKER_REGISTRY)
			       -u Container registry user name (default $DOCKER_USER)
				   -t 1Password Token URI (default: $ONEPASSWORD_URI)

			Deprecated:
				Usage:
				echo $DOCKER_PASSWORD | docker-login.sh -r docker.io -u richt
				echo $GITHUB_PAT | docker-login.sh -r ghcr.io -u richt
				   -l location of the secret file (default:"$DOCKER_SECRET_FILE") deprecated
				   -s instead of reading from stdin look in a file deprecated (default: $USE_SECRET_FILE)
				   -m docker machine to use for login is now deprecated (default $DOCKER_MACHINE)
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
	l)
		DOCKER_SECRET_FILE="$OPTARG"
		;;
	m)
		DOCKER_MACHINE="$OPTARG"
		;;
	r)
		DOCKER_REGISTRY="$OPTARG"
		;;
	s)
		USE_SECRET_FILE="$($USE_SECRET_FILE && echo false || echo true)"
		;;
	t)
		ONEPASSWORD_URI="$OPTARG"
		;;
	u)
		DOCKER_USER="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-docker.sh lib-util.sh

if in_os docker; then
	log_exit "in docker already"
fi

package_install jq

# this is now a warning as multiple logins are available
if [[ -e $HOME/.docker/config.json && -n "$(jq '.auths[].auth' "$HOME/.docker/config.json")" ]] && ! $FORCE; then
	log_warning "config.json exists and has an authorized login"
fi

if in_os mac; then

	if [[ -v DOCKER_MACHINE ]] && [[ ! -e /Applications/Docker.app ]] && ! docker-machine active; then
		log_verbose "using docker machine to login at $DOCKER_MACHINE"
		if ! docker-machine status "$DOCKER_MACHINE" | grep Running; then
			if ! docker-machine ls | grep "$DOCKER_MACHINE"; then
				docker-machine create --driver virtualbox default
			else
				docker-machine start "$DOCKER_MACHINE"
			fi
		fi
		eval "$(docker-machine env "$DOCKER_MACHINE")"
	fi

elif in_os linux; then
	# https://github.com/docker/docker/issues/12002
	# need to ignore error if started already
	if sudo service docker status | grep -F stop; then
		# note that start returns 1 if it is already started
		# If you do not have sudo, this will just fail
		echo "$SCRIPTNAME: docker service stopped, trying to restart if you can sudo"
		sudo -n service docker restart
	fi

	if ! grep -q "^docker" /etc/group; then
		log_exit 1 no docker group you should create with usermod -aG or iam-key
	fi

	if ! groups | grep -q docker; then
		log_warning not in docker group did you edit /opt/tongfamily/iam-key.conf.yml to
		log_warning to allow dev-ssh to use docker next sudo service iam-key restart
		log_exit 2 "otherwise manually add usermod -aG docker and relogin"
	fi

fi

if ! docker_available; then
	log_exit 3 "docker daemon not running"

fi

	# https://github.com/community/community/discussions/38467
	log_verbose "Note for ghcr.io only classis tokens are supported so do not use fine grained"
if $LOGIN_ALL; then
	export URI="$DOCKER_TOKEN_URI"
	# shellcheck disable=SC2086
	op run -- printenv URI | docker login $DOCKER_REGISTRY --username="$DOCKER_USER" --password-stdin
	export URI="$GITHUB_TOKEN_URI"
	# shellcheck disable=SC2086
	op run -- printenv URI | docker login $GITHUB_REGISTRY --username="$GITHUB_USER" --password-stdin
	gcloud auth configure-docker
fi

if [[ $DOCKER_REGISTRY =~ gcr.io ]]; then
	# https://cloud.google.com/container-registry/docs/advanced-authentication#gcloud-helper
	log_verbose "Google Cloud has its own configuration assumes you are gh auth login or gh auth activate-service-account"
	gcloud auth configure-docker
elif [[ -n $DOCKER_REGISTRY  && -n $DOCKER_TOKEN_URI]]; then
	# https://developer.1password.com/docs/cli/shell-plugins/github/
	log_verbose "Recommend using 1Password to store Access Tokens"
	# use printenv as shell variable substitution needs to be delayed
	# so that op can process it as a shell variable
	export URI="$DOCKER_TOKEN_URI"
	# shellcheck disable=SC2086
	op run -- printenv URI | docker login $DOCKER_REGISTRY --username="$DOCKER_USER" --password-stdin
elif $USE_SECRET_FILE; then
	# do not quote since null registry defaults to hub.docker.com
	# shellcheck disable=SC2086
	docker login $DOCKER_REGISTRY --username="$DOCKER_USER" --password-stdin <"$DOCKER_SECRET_FILE"
elif [[ -n $DOCKER_PASSWORD ]]; thne
	log_verbose "For docker login, you can use the web based login in Docker graphical apps"
	log_verbose "Otherwise hub.docker.com personal access token for $DOCKER_USER"
	log_verbose "You should create a personal access token "
	# do not quote since null registry defaults to hub.docker.com
	# shellcheck disable=SC2086
	docker login $DOCKER_REGISTRY --username="$DOCKER_USER" --password "$DOCKER_PASSWORD"
fi

# now that newgrp doesn't work because this is interactive
# http://stackoverflow.com/questions/29199884/running-docker-without-sudo-on-ubuntu-14-04
# Need to make groups take effect immediately not run
# http://stackoverflow.com/questions/299728/how-do-you-use-newgrp-in-a-script-then-stay-in-that-group-when-the-script-exits
if "$VERBOSE"; then
	echo "$SCRIPTNAME: Testing Docker works"
	if in_os linux; then
		log_verbose on linux need to be in the docker group so pipe into newgrp
		newgrp docker <<<"docker run hello-world"
	else
		docker run hello-world
	fi
fi
