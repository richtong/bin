#!/usr/bin/env bash
##
## Run benchmarks
## http://dustymabe.com/2012/12/30/running-benchmarks-with-the-phoronix-test-suite/
## See https://openbenchmarking.org/ for list of popular tests
## https://www.fossmint.com/benchmark-apps-to-measure-mac-performance/
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

# note pts/stress-ng does not run
# note pts/caffe does not compile
# note pts/cpu hangs on install
# https://gist.github.com/anshula/728a76297e4a4ee7688d
# using the recommended mac tests instead
#TEST=(pts/disk pts/compiler pts/gputest)
if [[ -v TEST ]]; then
	TEST=(
		pts/encode-flac pts/gmpbench pts/blender pts/brl-cad
		pts/fio pts/sockperf pts/stream
	)
fi
RESULTS=${RESULTS:-"$HOME/.phoronix-test-suite/test-results"}
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: Install and run standard tests"
		echo "flags: -d debug, -v verbose -h help"
		echo "positionals are phoronix test names (default: ${TEST[*]})"
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
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

shift $((OPTIND - 1))
if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	TEST=("$@")
fi

set -u

log_verbose installing phoronix
"$SCRIPT_DIR/install-benchmark.sh"

# https://formulae.brew.sh/formula/phoronix-test-suite
log_verbose "Getting to the test directory"
if ! pushd "$(brew --prefix)/share/phoronix-test-suite"; then
	log_error 1 "No $(brew --prefix)/share/phoronix-test-suite exists"
fi

phoronix-test-suite make-download-cache
# https://wiki.mikejung.biz/Phoronix_Test_Suite#How_to_install_Phoronix_test_suite_on_Ubuntu_14.10
if [[ ! -e $HOME/.phoronix-test-suite/user-config.xml ]]; then
	log_verbose "Creating user configuration"
	phoronix-test-suite batch-setup
fi

log_verbose "login to site"
phoronix-test-suite openbenchmarking-login

log_verbose "starting tests ${TEST[*]}"
log_verbose "For tests to run must in the correct directory"

# https://github.com/phoronix-test-suite/phoronix-test-suite/blob/master/documentation/phoronix-test-suite.md
if $VERBOSE; then
	phoronix-test-suite system-info
	phoronix-test-suite list-recommended-tests
fi

CONFIG="${CONFIG:-"$HOME/.phronix-test-suite/user-config.xml"}"
if [[ ! -e $CONFIG ]] || ! grep -q BatchMode "$CONFIG"; then
	log_verbose "No user config found creating it"
	phoronix-test-suite batch-setup
fi

#https://www.smartystreets.com/blog/2015/10/performance-testing-with-phoronix
log_verbose "running ${TEST[*]}"
phoronix-test-suite batch-benchmark "${TEST[@]}"
phoronix-test-suite upload-result

echo "check results in $RESULTS by open index.html there"
ls "$RESULTS"

if ! popd >/dev/null; then
	log_warning "could not return to the entry working directory"
fi
