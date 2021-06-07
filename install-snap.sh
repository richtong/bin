#!/usr/bin/env bash
##
## Installs snap on WSL2
## https://github.com/microsoft/WSL/issues/5126
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Snap on WSL2 by hacking at systemd
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
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

source_lib lib-install.sh lib-util.sh lib-config.sh

if ! in_wsl; then
	log_exit "WSL2 only"
fi

log_exit "the sudo nsenter does not run under wsl2"

# https://github.com/microsoft/WSL/issues/5126
# this needs to apt-get installed since brew installs do not
# work with sudo
sudo apt-get install -y daemonize dbus-user-session fontconfig

if ! config_mark; then
	config_add <<'EOF'
SYSTEMD_ARGS="--fork --pid --mount-proc /lib/systemd/systemd --system-unit=basic.target"
SYSTEMD_START=false
# shellcheck disable=SC2034
for i in {1..10}; do
	SYSTEMD_PID="$(pgrep -f -- "$SYSTEMD_ARGS")"
	if [[ -n $SYSTEMD_PID ]] && (( SYSTEMD_PID != 1 )); then
		break
	fi
	if ! $SYSTEMD_START; then
		# shellcheck disable=SC2086
		sudo daemonize /usr/bin/unshare $SYSTEMD_ARGS
		SYSTEMD_START=true
	fi
	sleep 1
done
exec sudo nsenter -t "$SYSTEMD_PID" -a su - "$LOGNAME"
EOF
fi
