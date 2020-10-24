#!/usr/bin/env bash
##
## Install Apache Airflow and Breeze
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
AIRFLOW_REPO="${AIRFLOW_REPO:=""}"
AIRFLOW_SOURCES="${AIRFLOW_SOURCE:=""}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvs:r:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Apache Airflow and Breeze. Assumes you have cloned the Airflow repo
			And you are using the package for other uses
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help"
			           -r Airflow repo location (default: SOURCE_DIR/extern/airflow)
			           -s Airflow files go here (default: SOURCE_DIR/airflow/breeze)

			  Note: you must symlink out the repo/files to check it in properly
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
	s)
		AIRFLOW_SOURCES="$OPTARG"
		;;
	r)
		AIRFLOW_REPO="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh

if ! in_os mac; then
	log_exit "Mac only"
fi

log_verbose install apache-airflow
cask_install apache-airflow

if [[ -z $AIRFLOW_SOURCES ]]; then
	AIRFLOW_REPO="$SOURCE_DIR/extern/airflow"
fi
log_verbose "Airflow repo at $AIRFLOW_REPO"

if [[ -z $AIRFLOW_REPO ]]; then
	AIRFLOW_REPO="$SOURCE_DIR/extern/airflow"
fi
log_verbose "Airflow repo at $AIRFLOW_REPO"

if [[ ! -e $AIRFLOW_REPO/breeze ]]; then
	log_error 1 "$AIRFLOW_REPO does not have breeze"
fi

log_verbose setup autocomplete
# do not worry if you say no and the exit code is bad
if ! "$AIRFLOW_REPO/breeze" setup-autocomplete; then
	log_verbose setup-autocomplete return $?
fi

if ! config_mark; then
	log_verbose "configuring $(config_profile)"
	config_add <<-EOF
		PATH+=":$AIRFLOW_REPO"
	EOF
fi

log_verbose "symlink $AIRFLOW_SOURCES to $AIRFLOW_REPO/files"

mkdir -p "$AIRFLOW_SOURCES"
rm -r "$AIRFLOW_REPO/files"
ln -s "$AIRFLOW_SOURCES" "$AIRFLOW_REPO/files"

log_warning "source $PROFILE before starting then run breeze"
