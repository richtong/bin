#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
#
## Install all the repos. First check the connectino exists
## @author rich
##
## Also restricts master pushs
##
##
## git_check_connection git-key
##
## git_install_or_update [ -f ] repo [ organization ]
## Remember use only local variables!
## Assumes HOME and SCRIPTNAME are set
##
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

FORCE="${FORCE:-false}"
OPTIND=1
# Initial capitals for user
# https://stackoverflow.com/questions/12487424/uppercase-first-character-in-a-variable-with-bash
while getopts "hdvw:f" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: flags: -d debug, -h help
            echo "    -w WS directory"
            echo "    -f force reset to origin/master (default: $FORCE)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
        f)
            FORCE=true
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-version-compare.sh lib-install.sh lib-util.sh

# Need to launch ssh in a subshell so ssh doesn't use the rest of the string as
# a command. Note we need to turn off pipefail temporarily because the ssh actually does
# report no interactive shell available
# In batch mode, make sure we do not get the host prompt and we do it just this once
set +o pipefail
if ! (exec ssh -o StrictHostKeyChecking=no -T git@github.com ) 2>&1 | grep -q "successfully authenticated"
then
    log_warning "either no ssh key because you did not setup .ssh"
    log_warning "or you did not ssh into with ssh-key forwarding on"
    log_error 2 "or no internet could not get into git hub"
fi

# Make sure git is there
package_install git


mkdir -p "$WS_DIR"/git
pushd "$WS_DIR/git" > /dev/null
if $FORCE
then
    FORCE_FLAG="-f"
fi
# Note these repo names change so you can add any repos in the account
for repo in src
do
    log_verbose working on $repo
    if ! git_install_or_update ${FORCE_FLAG-} "$repo"
    then
        log_warning could not update $repo
    fi
    log_verbose do not installing master push check for $repo
        log_verbose use github.com instead to protect master
        # "$SCRIPT_DIR/git-master-protect.sh" "$repo"
        log_verbose Now that we have the ssh keys, switch the $repo repo from https to git
        git_set_ssh "$repo"
    done
    popd >/dev/null
