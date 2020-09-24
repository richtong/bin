#!/usr/bin/env bash
##
## Run phoronix tests
## http://dustymabe.com/2012/12/30/running-benchmarks-with-the-phoronix-test-suite/
## See https://openbenchmarking.org/ for list of popular tests
##
##@author Rich Tong
##@returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# note pts/stress-ng does not run
# note pts/caffe does not compile
# note pts/cpu hangs on install
TESTS=${TESTS:-"pts/disk pts/compiler pts/gputest"}
RESULTS=${RESULTS:-"$HOME/.phoronix-test-suite/test-results"}
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install and run standard tests
            echo "flags: -d debug, -v verbose -h help"
            echo "positionals are phoronix test names (default: $TESTS)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

shift $((OPTIND-1))
if (( $# > 0 ))
then
    # https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
    TESTS="$@"
fi

set -u

if [[ ! $OSTYPE =~ linux ]]
then
    log_error 1 "only runs on linux"
fi

log_verbose installing phoronix
"$SCRIPT_DIR/install-phoronix.sh"

phoronix-test-suite make-download-cache
# https://wiki.mikejung.biz/Phoronix_Test_Suite#How_to_install_Phoronix_test_suite_on_Ubuntu_14.10
if [[ ! -e $HOME/.phoronix-test-suite/user-config.xml ]]
then
    phoronix-test-suite batch-setup
    phoronix-test-suite openbenchmarking-login
fi

log_verbose starting tests $TESTS
for test in $TESTS
do
    log_verbose running $test
    phoronix-test-suite install-dependencies "$test"
    phoronix-test-suite batch-benchmark "$test"
done
echo check results in $RESULTS by open index.html there
ls "$RESULTS"
