#!/usr/bin/env bash
##
## Install tmux and pljug ins
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
while getopts "hdv" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Tmux, the tmux plug in manager and tmux plugins
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
shift $((OPTIND-1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

brew install tmux tmuxinator
log_verbose tmuxinator requires latest ruby
"$SCRIPT_DIR/install-ruby.sh"

TMUX_REPO="${TMUX_REPO:="tmux-plugins-tpm"}"
TMUX_DIR="${TMUX_DIR:="$SOURCE_DIR/extern"}"
TMUX_CONF="${TMUX_CONF:="$HOME/.tmux/plugins/tpm"}"


if [[ ! -e $TMUX_CONF ]]
then
    mkdir -p "${TMUX_CONF%/*}"
    # https://tmuxcheatsheet.com/tmux-plugins-tools/?full_name=tmux-plugins%2Ftpm
    if [[ ! -e "$TMUX_DIR/$TMUX_REPO" ]]
    then
        mkdir -p "$TMUX_DIR"
        pushd "$TMUX_DIR" || log_exit "could not enter $TMUX_DIR"
        git submodule add "https://github.com/tmux-plugins/tpm" "$TMUX_REPO"
    fi

    ln -s "$TMUX_DIR/$TMUX_REPO" "$TMUX_CONF"
fi

if ! config_mark "$HOME/.tmux.conf"
then
    config_add "$HOME/.tmux.conf" <<-EOF
set -g @plugin 'tmux-plugins/tpm'
# sensible defaults
set -g @plugin tmux-sensible
# continuous save for auto restore
set -g @plugin 'tmux-plugins/tmux-continuum'
# C-B/C-S to save and C-B/C-R to restore
set -g @plugin 'tmux-plugins/tmux-resurrect'

# tmux panes and vim splits
set -g @plugin 'christoomey/vim-tmux-navigator'

# source this file and then
# always run at the end with CTRL-B and Capital I
run '~/.tmux/plugins/tpm/tpm'
EOF
fi

# https://thoughtbot.com/blog/templating-tmux-with-tmuxinator
log_verbose "run tmux source ~/.tmux.conf and add a plugin then"
log_verbose "with source ~/.tmux.conf and then CTRL-B capital I"
log_verbose "to create run cd to directory tmuxinator new project-name"
log_verbose "then run with tmuxinater start project-name"
