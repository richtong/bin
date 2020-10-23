#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Runs the cloud installation for selfhost
## This version uses env: and environment variables
##
## seeing passwords history or with ps
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
CLOUD_USER=${CLOUD_USER:-"$USER"}
ORG_NAME="${ORG_NAME:-tongfamily}"
DOCKER_USER=${DOCKER_USER:-"${ORG_NAME}build"}
GIT_EMAIL=${GIT_EMAIL:-"build@$ORG_NAME"}
CLOUD_SSL_PEM=${CLOUD_SSL_PEM:-"$CLOUD_USER.key.pem"}
BRANCH=${BRANCH:-"master"}
while getopts "hdvw:u:e:r:s:b:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			            $SCRIPTNAME: create a self-host cloud entry
			flags: -d debug, -h help"
			-c user for cloud instance (default: $CLOUD_USER)"
			-w WS directory (default: $WS_DIR)"
			-e Github user for cloud (default $GIT_EMAIL)"
			-r Docker user (default: $DOCKER_USER)"
			-s SSL key for cloud in pem (default: $CLOUD_SSL_PEM)"
			-b src branch to build (default: $BRANCH)"
			Enter passwords interactive or export shell variables"
			"GITHUB_PASS for $GIT_EMAIL"
			"DOCKER_PASS for docker user $DOCKER_USER"
			"CLOUD_PASS for cloud key $CLOUD_SSL_PEM"
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	w)
		WS_DIR="$OPTARG"
		;;
	u)
		CLOUD_USER="$OPTARG"
		;;
	e)
		GIT_EMAIL="$OPTARG"
		;;
	r)
		DOCKER_USER="$OPTARG"
		;;
	s)
		CLOUD_SSL_PEM="$OPTARG"
		;;
	b)
		BRANCH="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

shift $((OPTIND - 1))

SSL_CERT_DIR=${SSL_CERT_DIR:-"$WS_DIR/git/public-keys/ssl/certs"}
GITHUB_SSH_KEY=${GITHUB_SSH_KEY:-"$HOME/.ssh/$GIT_EMAIL-github.com.id_ed25519"}

# http://stackoverflow.com/questions/3980668/how-to-get-a-password-from-a-shell-script-without-echoing
if [[ -z $GITHUB_PASS ]]; then
	read -rsp "$GITHUB_SSH_KEY passphrase? " GITHUB_PASS
	echo
fi
export GITHUB_PASS

if [[ -z $DOCKER_PASS ]]; then
	read -rsp "$DOCKER_USER docker password? " DOCKER_PASS
	echo
fi
export DOCKER_PASS

if [[ -z $CLOUD_PASS ]]; then
	read -rsp "$CLOUD_SSL_PEM passphrase? " CLOUD_PASS
	echo
fi
export CLOUD_PASS

set -u

set_fd() {
	exec 3<<<"$GITHUB_PASS" \
		4<<<"$DOCKER_PASS" \
		5<<<"$CLOUD_PASS"
}
set_fd
if "$VERBOSE"; then
	for i in 3 4 5; do
		echo -n "fd $i has: "
		cat <&$i
	done
	set_fd
fi

# http://stackoverflow.com/questions/9340129/test-stdout-and-stderr-redirection-in-bash-script
if [[ ! -t 0 ]]; then
	log_error must run interactively and not redirect stdin from a tty
fi

command="
    $WS_DIR/git/src/scripts/server/create-ec2-server.py
    -d
    --server-class srioservice
    --dns-name $CLOUD_USER-cloud.alpha.$ORG_NAME
    --secret github-ssh-key=ssh-key[env:GITHUB_PASS]:file:$GITHUB_SSH_KEY
    --secret docker-password=data:env:DOCKER_PASS
    --secret ssl-key=ssl-key[env:CLOUD_PASS]:file:$HOME/.ssh/$CLOUD_SSL_PEM
        --artifact intermediate-ca-ssl-certs=$SSL_CERT_DIR/$CLOUD_USER-cloud.alpha.$ORG_NAME/cert-chain.pem
    --artifact ssl-cert=$SSL_CERT_DIR/$CLOUD_USER-cloud.alpha.$ORG_NAME/cert.pem
        --artifact root-ca-ssl-cert=$SSL_CERT_DIR/$CLOUD_USER-cloud.alpha.$ORG_NAME/root-cert.pem
        --git-branch $BRANCH
        "
# In new jhl-cloud build we do not need this
# --artifact "nginx.conf=$WS_DIR/git/src/cloud/server/class/srioservice/package/nginx.conf" \
log_verbose "$command"
log_verbose "executing command"
$command
