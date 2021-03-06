#!/usr/bin/env bash
##
## upgrades the various package managers
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
			Upgrades all the package managers
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
source_lib lib-util.sh

if in_os mac; then
	if is_command brew; then
		log_verbose "brew upgrade"
		brew update
		brew upgrade
	fi
elif in_os linux; then
	log_verbose "apt-get upgrade"
	apt-get update
	apt-get upgrade
fi

if is_command npm; then
	log_verbose "npm global update"
	npm -g update
fi

if is_command pip; then
	# https://stackoverflow.com/questions/2720014/how-to-upgrade-all-python-packages-with-pip
	# https://dougie.io/answers/pip-update-all-packages/
	log_verbose "pip upgrade"
	pip freeze | cut -d = -f 1 | xargs -n1 pip install --upgrade
fi
