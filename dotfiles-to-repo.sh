#!/usr/bin/env bash
##
## Copies dotfiles into your personal repo on a per user basis
## Then relink them with dotfiles-stow.sh
## On other machines you can run them
##
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
DOTFILES_ROOT=${DOTFILES_ROOT:-"$(cd "$SCRIPT_DIR/../user/$USER/dotfiles" && pwd -P)"}
FORCE="${FORCE:-false}"
SRC="${SRC:-"$HOME"}"
if [[ $OSTYPE =~ darwin ]]
then
    PACKAGE="${PACKAGE:-macos}"
else
    PACKAGE="${PACKAGE:-linux}"
fi
DOTFILES="${DOTFILES:-".bashrc .profile .bash_profile .dircolors .dir_colors \
    .stylelintrc .aws/config .ssh/known_hosts .gitconfig \
    .vimrc .eslintrc.js"}"
while getopts "hdvfs:t:p:" opt
do
    case "$opt" in
        h)
            cat <<-EOF

Moves your key dotfiles into your personal repo and links them back
You should run to initialize your dotfiles, then everything is under git control

    usage: $SCRIPTNAME [ flags ] [ destination for dotfiles]

    flags: -d debug, -v verbose, -h help"
           -f force the copy of the dotfiles on top of existing files in targer (default: $FORCE)
           -s source of your dotfiles (default: $SRC)
           -t target directory of dotfiles (default: $DOTFILES_ROOT)
           -p package where you want to move it the default is into your
              operating system (eg darwin for Mac, ubuntu, debian). If this is a
              file that is very version specific then use dot notation, so macos.10.12 is MacOS Sierra,
              macos.10.13 is MacOS High Sierra, and Ubuntu 16.04 is
              linux.ubuntu.16.04 (default: $PACKAGE)

    positional: list of dotfiles you want to put into the repo for control

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
            FORCE=true
            FLAGS+=" -f "
            ;;
        s)
            SRC="$OPTARG"
            ;;
        t)
            DOTFILES_ROOT="$OPTARG"
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh

if (( $# > 0 ))
then
    log_verbose using positionals $@
    DOTFILES="$@"
fi

target="$DOTFILES_ROOT/$PACKAGE"
log_verbose saving to $target
mkdir -p "$target"

log_verbose processing $DOTFILES
for dotfile in $DOTFILES
do
    if [[ ! -e $SRC/$dotfile ]]
    then
        log_verbose $SRC/$dotfile not found
        continue
    fi
    util_backup "$SRC/$dotfile"
    if [[ -L $SRC/$dotfile ]]
    then
        log_warning "$SRC/$dotfile" is already symlinked did you already run stow?
    fi

    if [[ -e $target/$dotfile ]]
    then
        log_verbose $target/$dotfile already exists
        if diff "$target/$dotfile" "$SRC/$dotfile" >/dev/null
        then
            log_verbose and $target and $SRC have the same $dotfile
            continue
        fi
        if ! $FORCE
        then
            log_verbose $SRC/$dotfile differs from $target use -f to change
            continue
        fi
    fi
    log_verbose found $dotfile and moving it to $DOTFILES_ROOT
    # note the $FORCE override the interactive -i
    mv $FLAGS "$SRC/$dotfile" "$target"
done

log_verbose moves complete you should commit when you are happy with $target and then run "$SCRIPT_DIR/dotfiles-stow.sh"
