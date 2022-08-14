#!/usr/bin/env bash
##
## install zfs-autosnapshot
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
POOL="${POOL:-zfs}"
FREQUENCY=${FREQUENCY:-(frequent hourly daily weekly monthly)}
SETTING=${SETTING:-(false false false true true)}
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvp:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs automatic snapshots for zfs
			    usage: $SCRIPTNAME [ flags ] [ positionals ]
			    flags: -d debug, -v verbose, -h help"
			           -p zfs pool (default: $POOL)

			    for frequnecy
			    $FREQUENCY

			    with default settings:
			    $SETTING

		EOF
		#    positionals: an array of ${#FREQUENCY[@]}
		#   ${FREQUENCY[@]}
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
	p)
		POOL="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

declare -a SETTING
if (($# > 0)); then
	SETTING=("$@")
fi

log_verbose "setup zfs-auto-snapshot as of Ubuntu 16.04.2 not in standard install"
apt_repository_install ppa:bob-ziuchkovski/zfs-auto-snapshot
package_install zfs-auto-snapshot

sudo zfs set com.sun:auto-snapshot=true "$POOL"
log_verbose "change zfs-auto-snapshot to only do weekly and monthly backups"
log_verbose to turn on set period to frequent, hourly or daily
log_verbose on with sudo zfs set com.sun:auto-snapshot:_period_=true
for i in $(seq 0 "$((${#FREQUENCY[@]} - 1))"); do
	p="${FREQUENCY[$i]}"
	# if setting does not exist assume it is false
	s="${SETTING[$i]}"
	log_verbose "checking $i in $p and $s"
	if [[ $(sudo zfs get "com.sun:auto-snapshot:$p" "$POOL" | awk 'NR==2 {print $3}') == '-' ]]; then
		log_verbose "$p was not set so make it $s"
		sudo zfs set "com.sun:auto-snapshot:$p=$s" "$POOL"
	fi
done
