#!/usr/bin/env bash
##
## Remove all snapshots
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1
POOL="${POOL:-zfs}"
FORCE="${FORCE:-true}"
DATASETS="${DATASETS:-"home data"}"
FLAGS="${FLAGS:-""}"
while getopts "hdvfp:s:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			$SCRIPTNAME: Destory all snapshots this is not recoverable
			so the default is just to display what it would

			    flags: -d debug, -h help
			           -f really destroy (default: $FORCE)
			           -p zfs pool (default: $POOL)

			   positional: zfs datasets (default: $DATASETS)

		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	f)
		FORCE=true
		FLAGS+=" -v "
		;;
	p)
		POOL="OPTARG"
		;;
	s)
		DATASETS="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-fs.h
shift $((OPTIND - 1))

if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	DATASETS=("$@")
fi

log_verbose removes all ZFS pools
for dataset in "${DATASETS[@]}"; do
	log_verbose "removing snapshots for  $dataset"
	if ! $FORCE; then
		FLAGS+=" -vn "
		log_verbose "will only do a dry run"
	else
		log_warning force is set really deleting
	fi

	snapshots="$POOL/$dataset@"
	log_verbose snapshot list without anything after the @ sign means all of them
	log_verbose by default we use -r for recursive
	# shellcheck disable=2086
	sudo zfs destroy -r $FLAGS "$snapshots"
done
