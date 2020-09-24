#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## Run system tests assuing the build is correct
##
## @author Rich Tong
## @returns 0 on success
#
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# Crontab jobs do not source anything, so we need to do it manually
source "$HOME/.bash_profile"
# USER is not defined in chron so set to the Logon name
USER=${USER:-"$LOGNAME"}
TEST_HOST=${TEST_HOST:-"$HOSTNAME"}
OPTIND=1
while getopts "hdv" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME runs system tests for alpha
            echo flags: -d debug, -h help, -v verbose
            echo "       -h hostname to test (default is $TEST_HOST)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;&
        v)
            VERBOSE=true
            ;;
        h)
            TEST_HOST="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh

# get to positional parameters
shift "$((OPTIND - 1))"

package_install jq

pushd "$WS_DIR/git/src" > /dev/null

log_verbose Start system testing
run_system

errors=0
tests=0

# http://mywiki.wooledge.org/BashPitfalls
# Note that is an (()) ever evaluates to a zero
# then the return code is an error failue code and with set -e
# this stops, so never do a ((tests++)) as the first iteration
# will fail, always do ((++tests)) so non-zero results alway return a 0 error
# code
# Note we only go to stderr, so you can pipe the actual output
run_test(){
    # need two parameters
    if (( $# == 2 ))
    then
        log_verbose $1 testing
        ((++tests))
        if ! eval $2
        then
            ((++errors))
            >&2 echo $SCRIPTNAME: $tests. $1 failed
        else
            log_verbose $tests. $1 passed
        fi
    fi
}

if [[ -e "$WS_DIR/var/shared/local/app-host.config" ]]
then
    log_verbose Testing cameras directly
    # need a special json query parser
    if command -v jq
    then
        for c in 0 1
        do
            ip=$(jq .camera$c)
            if [[ -n "$ip" ]]
            then
                run_test "camera $c at $ip" "curl http://$ip:8080/"
            fi
        done
    fi

fi

log_verbose $SCRIPTNAME: Testing app-host

host_url="http://$TEST_HOST.local"

run_test "Web server" 'curl $host_url | grep -q Apache'

# this is hard to pass because of expansion
# So just use eval to get it out as a string
run_test "API server" 'curl $host_url:5000 | grep -q "API server"'

# http://stackoverflow.com/questions/14978411/http-post-and-get-using-curl-in-linux

for n in 0 1
do
    run_test "Create moment" \
        'curl -X POST "$host_url:5000/moments/camera$n"'

done

all_moments=$(run_test "Get list of moments" \
    'curl -X GET "$host_url:5000/moments"')

# Need to figure out how to get the whole list of moments but
# here we just get the latest
declare -a moments
for cam in 0 1
do
    moments[$cam]=$(echo $all_moments | jq ".cameras.camera$n.moments[]")

    log_verbose found moment for camera $n at $moment_url_$n
    count=0
    for moment in ${moments[$cam]}
    do
        ((++count))
        run_test "Get $count m3u8 for camera $cam" "curl $moment"
        run_test "Get $count video for camera $cam" \
            "vlc $moment --stop-time=15 vlc://quit"

    done


    run_test "Play lullaby" 'curl -X POST "$host_url:5000/lullaby"'

    run_test "Stop lullaby" 'curl -X DELETE "$host_url:5000/lullaby"'

    run_test "Toggle rects" 'curl -X POST "$host_url:5000/rects"'

    # This line for saving the output note we
    # do not need backslashes with single quotes
    for n in 0 1
    do
        run_test "Switch to camera $n" \
            "vlc rtsp://$TEST_HOST.local:8554/camera$n
        --stop-time=15 vlc://quit"
    done


    popd >/dev/null

    # Pass back error count
    log_verbose ran $tests tests had $error errors

    exit $errors
