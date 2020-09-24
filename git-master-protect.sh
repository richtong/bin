#!/usr/bin/env bash
##
## Installs a pre-push hook to prevent accidental master pushs
## https://dev.ghost.org/prevent-master-push/
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
REPOS=${REPOS:-"$SOURCE_DIR"}
OPTIND=1
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: prevent master pushes without a question
            echo "flags: -d debug, -h help -v verbose"
            echo "positional: list or repos to protect (default: $REPOS)"
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
source_lib lib-util.sh lib-config.sh
shift $((OPTIND-1))
REPOS=${@:-$REPOS}

# https://stackoverflow.com/questions/19021978/how-to-block-push-to-master-branch-on-remote
log_exit for github this is better done in the user interface at settings/Branches/Protect This Branch

for repo in $REPOS
do
hook="$repo/.git/hooks/pre-push"
log_verbose checking $repo
mkdir -p "$(dirname "$hook")"
log_verbose if no $hook start a barebone shell script
if [[ ! -e "$hook" ]]
then
    config_add "$hook" <<<'#!/usr/bin/env bash'
fi
chmod +x "$hook"
if ! config_mark "$hook"
then
    log_verbose adding $hook
    # delay variable substituion with quotes
    # Use a backslash to prevent variable expansion in here doc
    # use quoted "EOF" to prevent any bash variable substitution at all
    # https://stackoverflow.com/questions/40462111/git-prevent-commits-in-master-branch/40465455
    config_add "$hook" <<-"EOF"
if [[ $(git rev-parse --abbrev-ref HEAD) == master ]]
then
  read -r -p "Really commit to master [y|N]? " response
  if [[ ${response,,} =~ ^y ]]
  then
      exit 1
  fi
fi
EOF
fi
# As of August 2017 this generates and error
# http://stackoverflow.com/questions/4937792/using-variables-inside-a-bash-heredoc
#if [[ master == $(git symbolic-ref HEAD | sed -e 's#.*/\(.*\)#\1#') ]]
#then
#    read -r -p "You are about to push to master [y|n]? " response
#    if [[ \${response,,} =~ ^(yes|y) ]]
#    then
#        exit 1
#    fi
#fi
done
