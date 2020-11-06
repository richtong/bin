#!/usr/bin/env bash
##
## Adds drives to zfs
##
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
POOL="${POOL:-"zfs"}"
DRYRUN="${DRYRUN:-false}"
FLAGS="${FLAGS:-""}"
FORCE="${FORCE:-false}"
while getopts "hdvp:nf" opt; do
	case "$opt" in
	h)
		cat <<EOF
$SCRIPTNAME: Add spare drives to ZFS
flags:  -d debug, -h help
        -p The ZFS pool to wich to add drives (default: $POOL)
        -r Dry run to see what it would do (default: $DRYRUN)
	-f Force the add (default: $FORCE)

        positionals: list of drives defaults to free drives on system
EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	p)
		POOL="$OPTARG"
		;;
	n)
		DRYRUN=true
		FLAGS+=" -n "
		;;
	f)
		FORCE=true
		FLAGS+=" -f "
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-avahi.sh lib-fs.sh
shift $((OPTIND - 1))

if [[ ! $OSTYPE =~ linux ]]; then
	log_exit "run on linux only"
fi

if (($# == 0)); then
	IFS=" " read -r -a disks <<<"$(disks_list_possible)"
else
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	disks=("$@")
fi
log_verbose "adding disks ${disks[*]}"

IFS=" " read -r -a layout <<<"$(zfs_disk_configuration "${disks[@]}")"
log_verbose "using zfs layout ${layout[*]} $POOL"
# Need an eval to get rid of quotes in the $layout
# shellcheck disable=SC2086
eval sudo zpool add $FLAGS "$POOL" "${layout[@]}"
