#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Create a swarm for the current user
##
## @author Rich Tong
## @returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

REMOTE_USER=${REMOTE_USER:-root}
ORG=${ORG:-tongfamily.com}
KEY=${KEY:-"$HOME/.ssh/$USER@$ORG-$ORG.id_ed25519"}
FORCE=${FORCE:-false}
# over kill for a single flag to debug, but good practice
OPTIND=1
while getopts "hdvu:k:f" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Swarm for the current user from organization machines"
		echo "flags: -d debug, -h help, -v verbose"
		echo "       -u user on remote machine (default: $REMOTE_USER)"
		echo "       -k private key for ssh logon on remote machine (default: $KEY)"
		echo "       -f force create of machine (default: $FORCE)"
		echo positionals: hostname1 hostname2 hostname3
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	u)
		REMOTE_USER="$OPTARG"
		;;
	k)
		KEY="$OPTARG"
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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
# lib-install.sh need by lib-network
source_lib lib-install.sh lib-network.sh
shift "$((OPTIND - 1))"

# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for host in "$@"; do
	if docker-machine inspect "$host"; then
		if $FORCE; then
			log_verbose machine exist, but forcing recreation
			docker-machine rm -f "$host"
		else
			continue
		fi
	fi

	# find the ip address of the host
	# http://serverfault.com/questions/170706/unix-shell-easy-way-to-get-ip-from-hostname

	fullhost="$(add_local "$host")"
	fullremote="$REMOTE_USER@$fullhost"
	ip="$(get_ip "$fullhost")"
	if [[ -z $ip ]]; then
		log_warning "ip for $host not found"
		continue
	fi
	log_verbose "installing ssh key on $host at $ip"
	# http://blog.hypriot.com/post/how-to-setup-rpi-docker-swarm/
	ssh-keygen -R "$ip"
	if ssh-copy-id -i "$KEY" "$fullremote"; then
		log_warning ssh-copy returned $?
	fi

	# https://docs.docker.com/machine/drivers/generic/
	log_verbose check if we are connecting to raspbian and change to debian
	ssh "$fullremote" sudo sed -i \'s/ID=raspbian/ID=debian/g\' /etc/os-release

	log_warning "this will disable docker if targeted at a raspberry pi without rpi-config.sh run on it "
	# without --generic-ssh-key docker-machine uses ssh-agent
	docker-machine create --driver generic \
		--generic-ip-address "$ip" \
		--generic-ssh-user "$REMOTE_USER" \
		"$host"
done
