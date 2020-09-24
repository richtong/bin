#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install vi tools
## https://davidosomething.com/blog/vim-for-javascript/
## There are a couple flavors of tools:
##  - Syntax highlighting. Try https://github.com/othree/yajs.vim
##  - Code completion
##  - Linting. ESlint, jsonlint, and different plugsin need to be installed to
##    syntastic
##
## Use install-vim.py for Ubuntu only. This is the same script but
## works for Darwin or for Ubuntu
##
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
export SCRIPTNAME
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

# Pass the force flag down
export FORCE=${FORCE:-false}
FLAGS="${FLAGS:-""}"
OPTIND=1
while getopts "hdvf" opt
do
    case "$opt" in
        h)
            echo "$SCRIPTNAME: Install vim plug ins"
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -f force reinstall (default: $FORCE)"
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            ;;
        f)
            FORCE=true
            FLAGS+=" -f "
            ;;
        *)
            echo "no flag $opt"
    esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh

package_flags=""
if [[ $OSTYPE =~ darwin ]]
then
    log_verbose will override vi as well as vim
    package_flags+=" --with-override-system-vi "
fi
package_install "${package_flags[@]}" vim

# http://eslint.org/docs/user-guide/command-line-interface.html
# https://github.com/yannickcr/eslint-plugin-react says
# jsx editing no longer requires babel and babel-eslint
# just use eslint-plugi-react but this does not work
#
# react https://github.com/jaxbot/syntastic-react
# csslint at
# https://michalzuber.wordpress.com/2014/12/03/css-syntax-errors-via-csslint-in-vim/
# jslint is used as a backup, but eslint is the main one
# we also lint json and yaml
# Note that npm_install does a -g global
# Note that csslint does not handle postcss so is disabled
# https://code.facebook.com/posts/879890885467584/improving-css-quality-at-facebook-and-beyond/
# Stylelint is what Facebook uses for PostCSS
# Parameters for these are set last in .vimrc
#
# To support react we need some more linters
# https://github.com/facebookincubator/create-react-app/blob/master/template/README.md#displaying-lint-output-in-the-editor
log_verbose make sure node is installed for the linters
"$SCRIPT_DIR/install-lint.sh"

# https://github.com/scrooloose/syntastic for multiple syntax checkers
mkdir -p "$HOME/.vim/bundle"
log_verbose install pathogen for legacy installs
if  [[ ! -e $HOME/.vim/autoload/pathogen.vim ]]
then
    log_verbose no pathogen.vim found
    log_verbose curling pathogen.vim
    # note that if there is an option error, curl does not return an error and -o
    # must be next to the file name
    curl --create-dirs -LSso "$HOME/.vim/autoload/pathogen.vim" https://tpo.pe/pathogen.vim
    if [[ ! -e $HOME/.vim/autoload/pathogen.vim ]]
    then
        log_error 2 "could not create pathogen.vim"
    fi
fi

# We could put into the .vimrc file as well, although this slows startup
# This does not do PlugUpgrades
log_verbose install vim-plug for new installs
if [[ ! -e $HOME/.vim/autoload/plug.vim ]]
then
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dir \
        "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi

log_verbose "now using vim-plug these installs are done in .vimrc, use"
log_verbsoe "PlugInstall and then PlugUpgrade in vim"
# scrooloose syntax checker
# bundle_install vim-syntastic syntastic
# terminal colors
# bundle_install altercation vim-colors-solarized
# editing json
# bundle_install elzr vim-json
# javascript syntax checker
# bundle_install othree yajs.vim
# https://github.com/lifepillar/vim-mucomplete
# bundle_install lifepillar vim-mucomplete
git config --global core.editor "vim"

log_verbose looking for personal spell checker files
# if spell is symlinked the mkdir will fail
if [[ ! -e "$HOME/.vim/spell" ]]
then
    if [[ -e "$WS_DIR/git/personal/$USER/vim/spell" ]]
    then
        ln -s "$WS_DIR/git/personal/$USER/vim/spell" "$HOME/.vim/spell"
    fi
fi

# the {-} says replace with "" if not present so set -u is not tripped
if ! config_mark "${FLAGS[@]}"
then
    # note we escape the command line so we check the path of vi at run time
    config_add <<EOF
VISUAL="$(command -v vi)"
export VISUAL
export EDITOR="$VISUAL"
EOF
log_verbose "source $(config_profile) to enable vi as default editor or relogin"
fi

log_verbose checking .vimrc which should be synced, but if not put in a default
if ! config_mark "${FLAGS[@]}" "$HOME/.vimrc" '"'
then
    log_verbose adding to .vimrc
    config_add "$HOME/.vimrc" <<EOF
set autoread
set incsearch
set showmatch
" Move to Google standard
set shiftwidth=2 tabstop=2 expandtab
set textwidth=80
" If you like numbering then set number particularly for python
set number
" modelines are a security hole but worthwhile for css files that like 2 indents
set modeline

set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1
let g:syntastic_mode_map = { 'mode' : 'active' }
let g:syntastic_javascript_checkers = ['eslint', 'jshint']
let g:syntastic_python_checkers = [ 'flake8', 'mypy', 'python' ]
au BufRead,BufNewFile *.json set filetype=json

" https://jaxbot.me/articles/setting-up-vim-for-react-js-jsx-02-03-2015
let g:jsx_ext_required = 0

"https://zanshin.net/2015/10/02/how-to-spell-check-with-vim/
" Turn on spell check for textal files
autocmd FileType md,markdown,txt setlocal spell spelllang=en_us
" This seems to not work with commits
autocmd BufRead COMMIT_EDITMSG setlocal spell spelllang=en_us
set spell spelllang=en_us
set spellfile=$HOME/.vim/en.utf-8.add

" https://github.com/lifepillar/vim-mucomplete
set completeopt+=menuone
inoremap <expr> <c-e> mucomplete#popup_exit("\<c-e>")
inoremap <expr> <c-y> mucomplete#popup_exit("\<c-y>")
inoremap <expr>  <cr> mucomplete#popup_exit("\<cr>")
set completeopt+=noselect
set completeopt+=noinsert
set shortmess+=c "shut off complete messages
set belloff+=ctrlg "if vim beeps during completeo
let g:mucomplete#enable_auto_at_startup = 1


" Initialize plugin system
" install bazel support to allow :Bazel build //main/package:target
" https://github.com/bazelbuild/vim-bazel
" pathogen is now deprecated use vim-plug
execute pathogen#infect()
syntax on
filetype plugin indent on

" https://github.com/junegunn/vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
          http://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source \$MYVIMRC
endif
" https://github.com/junegunn/vim-plug
" - Avoid using standard Vim directory names like 'plugin'
" - Put in the same place as pathogen
" call plug#begin('~/.vim/plugged')
call plug#begin('~/.vim/bundle')
" https://github.com/fatih/vim-go/blob/master/README.md#install
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
Plug 'junegunn/vim-plug'
Plug 'vim-syntastic/syntastic'
Plug 'altercation/vim-colors-solarized'
PLug 'elzr/vim-json'
Plug 'google/vim-maktaba'
Plug 'bazelbuild/vim-bazel'
Plug 'lifepillar/vim-mucomplete'
" completetion for python and javascript
Plug 'davidhalter/jedi-vim'
Plug 'othree/yajs.vim'

" https://www.vimfromscratch.com/articles/vim-for-python/
" Way more powerful syntax analysis that runs async
Plug 'dense-analysis/ale'
" Initialize plugin system
call plug#end()
EOF
fi
