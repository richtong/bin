#!/usr/bin/env bash
##
## Rename a repo from master to main
## https://hackernoon.com/how-to-rename-your-git-repositories-from-master-to-main-6i1u3wsu
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
REPOS="${REPOS:-""}"
FROM="${FROM:=master}"
TO="${TO:=main}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvt:f:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Renames a master branch to main for a set of repos
    The default is the current working directory
    usage: $SCRIPTNAME [ flags ] [ repos ]
    flags: -d debug, -v verbose, -h help"
           -f from-the-current-branch name (DEFAULT: $FROM)
           -t to-this-new-name (default: $TO)
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
        f)
            FROM="$OPTARG"
            ;;
        t)
            TO="$OPTARG"
            ;;
        *)
            echo "not flag -$opt"
            ;;
    esac
done
shift $((OPTIND-1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh

if [[ -z $REPOS ]]
then
    REPOS=("$PWD")
fi

for repo in "${REPOS[@]}"
do
    remote_repo="git@github.com:$REPO_ORG:$(basename "$repo")"
    log_verbose "renaming master in $repo to $TO from $FROM and at $remote_repo"
    # https://stackoverflow.com/questions/5167957/is-there-a-better-way-to-find-out-if-a-local-git-branch-exists
    if ! git rev-parse --verify "$FROM"
    then
        log_verbose "No $FROM in $repo skipping"
        continue
    fi
    if ! git -C "$repo" ls-remote --exit-code --heads "$remote_repo" "$TO"
    then
        log_verbose "No $FROM in $repo skipping"
    fi
    if git rev-parse --verify "$TO"
    then
        log_verbose "$TO already exists in $repo skipping"
        continue
    fi

    git -C "$repo" branch -m "$FROM" "$TO"
    git -C "$repo" checkout "$TO"
    git -C "$repo" push -u origin "$TO"
    # https://github.blog/2020-07-27-highlights-from-git-2-28/#introducing-init-defaultbranch
    git -C "$repo" push origin --delete "FROM"
    log_verbose "change default branch for $repo in github.com"
done
