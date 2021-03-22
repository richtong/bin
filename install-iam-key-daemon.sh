#!/usr/bin/env bash
##
## Install iam-key daemon which synchronizes accounts between AWS IAM and the
## local machine
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install IAM key synchronizer to local Linux"
		echo "flags: -d debug, -v verbose, -h help"
		echo "       -f force a default conf file"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt"
		;;
	esac
done
# shellcheck disable=SC1090
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh
shift $((OPTIND - 1))

if ! in_os linux; then
	log_exit "only for linux"
fi

log_verbose looking for iam synchronizer
if ! sudo service iam-key status | grep -wq running; then
	log_verbose running this later with a different user causes permission
	log_verbose denied errors even with sudo enabled
	package_install curl
	curl -s http://download.tongfamily.com/bootstrap/install-iam-key-daemon.sh | bash -s
	log_warning using default /etc/richtong/iam-key.conf.yml so no docker
	log_warning sudo access allowed, you should edit to just allow
	log_warning the users who want access. Do not leave wipe open
fi

if [[ ! -e /etc/opt/richtong/iam-key.conf.yml ]]; then
	sudo service iam-key restart
fi
