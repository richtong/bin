#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
## The above gets the latest bash on Mac or Ubuntu
##
##install and login docker
## Uses the wget method the first time for docker
## After that you can just sudo apt-get install docker-engine
##
## Note that we no longer need email as part of the
## login as of July 2017
##@author Rich Tong
##
#
set -ueo pipefail && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
DOCKER_USER=${DOCKER_USER:-netdrones-$USER}
DOCKER_MACHINE=${DOCKER_MACHINE:-default}
FORCE=false
while getopts "hdvu:m:f" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: logon to docker hub"
		echo "flags: -d debug, -h help"
		echo "       -u docker-user (default $DOCKER_USER)"
		echo "	     -m docker machine to use for login (default $DOCKER_MACHINE)"
		echo "       -f force a new login even if one already exists (default $FORCE)"
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
	u)
		DOCKER_USER="$OPTARG"
		;;
	m)
		DOCKER_MACHINE="$OPTARG"
		;;
	f)
		FORCE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-docker.sh lib-util.sh

if in_os docker; then
	log_exit in docker already
fi

package_install jq

if [[ -e $HOME/.docker/config.json && -n "$(jq '.auths[].auth' "$HOME/.docker/config.json")" ]] && ! $FORCE; then
	log_error 1 "config.json already has a logon do not overwrite"
fi

if in_os mac; then
	if [[ ! -e /Applications/Docker.app ]] && ! docker-machine active; then
		if ! docker-machine status "$DOCKER_MACHINE" | grep Running; then
			if ! docker-machine ls | grep "$DOCKER_MACHINE"; then
				docker-machine create --driver virtualbox default
			else
				docker-machine start "$DOCKER_MACHINE"
			fi
		fi
		eval "$(docker-machine env "$DOCKER_MACHINE")"
	fi
else
	# https://github.com/docker/docker/issues/12002
	# need to ignore error if started already
	if sudo service docker status | grep -F stop; then
		# note that start returns 1 if it is already started
		# If you do not have sudo, this will just fail
		echo "$SCRIPTNAME: docker service stopped, trying to restart if you can sudo"
		sudo -n service docker restart
	fi
fi

if ! grep -q "^docker" /etc/group; then
	log_exit 1 no docker group you should create with usermod -aG or iam-key
fi

if ! groups | grep -q docker; then
	log_warning not in docker group did you edit /opt/tongfamily/iam-key.conf.yml to
	log_warning to allow dev-ssh to use docker next sudo service iam-key restart
	log_exit 2 "otherwise manually add usermod -aG docker and relogin"
fi

if ! docker_available; then
	log_exit 3 "docker daemon not running"
fi

# http://stackoverflow.com/questions/29199884/running-docker-without-sudo-on-ubuntu-14-04
# Need to make groups take effect immediately not run
# http://stackoverflow.com/questions/299728/how-do-you-use-newgrp-in-a-script-then-stay-in-that-group-when-the-script-exits
# now that newgrp doesn't work because this is interactive
echo "$SCRIPTNAME: Enter hub.docker.com personal access token for $DOCKER_USER"
docker login --username="$DOCKER_USER"

if "$VERBOSE"; then
	echo "$SCRIPTNAME: Testing Docker works"
	if in_os linux; then
		log_verbose on linux need to be in the docker group so pipe into newgrp
		newgrp docker <<<"docker run hello-world"
	else
		docker run hello-world
	fi
fi
