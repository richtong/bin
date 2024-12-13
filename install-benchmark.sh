#!/usr/bin/env bash
##
## Run phoronix tests, geekbench, cinebench and other benchmarks
## http://dustymabe.com/2012/12/30/running-benchmarks-with-the-phoronix-test-suite/
## https://www.fossmint.com/benchmark-apps-to-measure-mac-performance/
## See https://openbenchmarking.org/ for list of popular tests
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
VERSION=${VERSION:-7.2.1}
while getopts "hdvr:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install Phoronix Test Suite"
		echo "flags: -d debug, -v verbose -h help"
		echo "       -r version to load (default: $VERSION)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	r)
		RELEASE="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh

shift $((OPTIND - 1))

set -u
MAS+=(

	425264550  # Blackmagic Disk speed deprecated for Amorphous
	1168254295 # Amorphous has more than just sequential
	1495719766 # Amorphous memory benchmark
)

PACKAGE+=(
	drivedx
	geekbench
	cinebench
	phoronix-test-suite
	geekbench-ai
)

if in_os mac; then
	log_verbose "installing MacOS benchmarking"
	package_install
	log_exit "Run Geekbench and Cinebench"
	exit
fi

log_verbose "installing Linux benchmarks Phoronix"
if in_linux ubuntu; then
	package_install phoronix-test-suite
else
	deb_install \
		phoronix-test-suite \
		"http://phoronix-test-suite.com/releases/repo/pts.debian/files/phoronix-test-suite_${RELEASE}_all.deb"
fi
