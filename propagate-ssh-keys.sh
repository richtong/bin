#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
#
# Propagate prebuild changes to all hosts
#
# A quick helper for debugging so that you can get all the private keys which
# are not in github to different machines when things change
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
HOSTS=${HOSTS:-"loki.local thor.local odin.local baldur.local vlads-zbox.local"}
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			      $SCRIPTNAME: Propagate prebuild sub directory to $HOME etc
			      flags: -d debug, -h help
			      list of hosts (default $HOSTS)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

shift "$((OPTIND - 1))"

if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	HOSTS=("$@")
fi

for host in "${HOSTS[@]}"; do
	scp -rp ./* "$host:prebuild"
	ssh "$host '(cd prebuild && ./prebuild-fix-permissions.sh)'"
done

# Now copy to local mac host
rsync -a ./* /mnt/hgfs/rich/prebuild
if ! cd /mnt/hgfs/rich/prebuild; then
	log_error 1 "no /mnt/hgfs/rich/prebuild"
fi
./prebuild-fix-permissions.sh
