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
while getopts "hdvf" opt; do
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
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh

package_flags=""
if [[ $OSTYPE =~ darwin ]]; then
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
if [[ ! -e $HOME/.vim/autoload/pathogen.vim ]]; then
	log_verbose no pathogen.vim found
	log_verbose curling pathogen.vim
	# note that if there is an option error, curl does not return an error and -o
	# must be next to the file name
	curl --create-dirs -LSso "$HOME/.vim/autoload/pathogen.vim" https://tpo.pe/pathogen.vim
	if [[ ! -e $HOME/.vim/autoload/pathogen.vim ]]; then
		log_error 2 "could not create pathogen.vim"
	fi
fi

# We could put into the .vimrc file as well, although this slows startup
# This does not do PlugUpgrades
log_verbose install vim-plug for new installs
if [[ ! -e $HOME/.vim/autoload/plug.vim ]]; then
	curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dir \
		"https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi

log_verbose "now using vim-plug these installs are done in .vimrc, use"
log_verbose "PlugInstall and then PlugUpgrade in vim"
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
if [[ ! -e "$HOME/.vim/spell" ]]; then
	if [[ -e "$WS_DIR/git/personal/$USER/vim/spell" ]]; then
		ln -s "$WS_DIR/git/personal/$USER/vim/spell" "$HOME/.vim/spell"
	fi
fi

# the {-} says replace with "" if not present so set -u is not tripped
if ! config_mark; then
	# note we escape the command line so we check the path of vi at run time
	config_add <<EOF
VISUAL="$(command -v vi)"
export VISUAL
export EDITOR="$VISUAL"
EOF
	log_verbose "source $(config_profile) to enable vi as default editor or relogin"
fi

log_verbose checking .vimrc which should be synced, but if not put in a default
# shellcheck disable=SC2086
if ! config_mark "$HOME/.vimrc" '"'; then
	log_verbose adding to .vimrc
	config_add "$HOME/.vimrc" <<-'EOF'
		set autoread
		set incsearch
		set showmatch
		" Tuned for python
		set shiftwidth=4 tabstop=4 expandtab
		set textwidth=79
		set number " numbers are ugly  but needed for Python
		" modelines are a security hole but worthwhile for css files that like 2 indents
		set modeline

		" Added by install-vim.sh on Thu Dec 29 12:20:51 PST 2016
		" No more pathogen

		" https://github.com/junegunn/vim-plug
		if empty(glob('~/.vim/autoload/plug.vim'))
		  curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
		        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
		  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
		endif

		" - Avoid using standard Vim directory names like 'plugin'
		" - Put in the same place as pathogen
		" call plug#begin('~/.vim/plugged')
		call plug#begin('~/.vim/bundle')

		" colorscheme tuned for Mac Terminal
		Plug 'altercation/vim-colors-solarized'
		" Use this for xterm2
		Plug 'lifepillar/vim-solarized8'

		" Using Powerline instead
		" https://www.tecmint.com/powerline-adds-powerful-statuslines-and-prompts-to-vim-and-bash/
		" better status line that is vim only
		"Plug 'vim-airline/vim-airline'
		"Plug 'vim-airline/vim-airline-themes'


		" fzf - fuzzy find with auto update of fzf
		" :Files [PATH] all files from PATH
		" :GFiles git ls-files
		" :Rg [PATTERN] run ripgrep
		" :Marks :Windows
		" Ctrl-t for new tab, Ctrl-x new split Ctrl-v vertical split
		Plug 'junegunn/fzf', { 'do' : {-> fzf#install() }}
		Plug 'junegunn/fzf.vim'

		" Navigate directory tree
		" https://medium.com/@victormours/a-better-nerdtree-setup-3d3921abc0b9
		" autocmd StdinReadPre to open is no argument
		Plug 'preservim/nerdtree'
		" shows git status in nerdtree
		" :NERDTree to start
		Plug 'xuyuanp/nerdtree-git-plugin'

		" improves the standard syntax highlighting
		" syntax highlighting includes stripped libraries load the full one if you want
		" https://vi.stackexchange.com/questions/7258/how-do-i-prevent-vim-from-hiding-symbols-in-markdown-and-json
		" Note the markdown one is plasticboy/vim-markdown called from ploygot
		" turn off the insert mode so that you can see the urls
		" let g:vim_markdown_math to enable Latex
		" gx - opens the link under the cursor (not the default gx opens a brownser)
		" ge - opens the link for editing in vim
		" ]] - next header, [[ previous header,
		"
		Plug 'sheerun/vim-polyglot'

		" Auto-pair parentheses etc
		" CR. return instests a new indented line
		" BS. Backspace deletes the pair of brackets
		" Alt-p Toggle autopairs. Not in Vim Alt is called the meta key see :help <>:w
		" Alt-e Fast wrap
		" Alt-n Jump to next pair
		" Alt-m back inserts
		Plug 'jiangmiao/auto-pairs'

		" \ci inverts a comment  \cc adds a comment \cs block formatter
		" \c space inverts the entire block
		Plug 'preservim/nerdcommenter'

		" Git in vi with :G commit,:G diff, :G difftool, :Gdiffsplit
		Plug 'tpope/vim-fugitive'
		" Git signs in the gutter
		Plug 'airblade/vim-gitgutter'

		" https://www.vimfromscratch.com/articles/vim-for-python/
		" ale not working properly with python 3 and duplicates syntastic
		" Plug 'dense-analysis/ale'

		" Linter that is synchronous but works well, better than COC
		Plug 'vim-syntastic/syntastic'


		" completion fallback chain
		" needs set completeopt+=menuone, set shortmess+=c, <tab> starts it
		" ctrl-h cancel menu and try a different completer
		" ctrl-j pick next completer
		" tab or shift-tab to change
		" Generating a startup error so disable
		" Plug 'lifepillar/vim-mucomplete'

		" Python syntax used with vim-mucomplete, and has complete language
		" understanding
		" <c-space> to complete
		" K for documentation  \g goto
		" \d find definition acdross imports  \s create a stub
		" \r rename a variable, \n for usages
		" Incompatible with python-mode
		" With neovim, use coc.nvim or deoplete-jedi instead for async
		Plug 'davidhalter/jedi-vim'

		" Json syntax highlighting, conceals double quotes
		" add folding with ftpluging/json.vim adding foldmethod=syntax
		Plug 'elzr/vim-json'

		" Python indenting
		Plug 'vimjas/vim-python-pep8-indent'
		" :Black to run the python reformatter
		Plug 'psf/black', {'branch': 'stable'}

		" This is not needed with neovim and coc.nvim
		" https://github.com/fatih/vim-go/blob/master/README.md#install
		" Python folding
		" zo: Open a fold
		" zc: Close a fold
		" zk: Jump to the previous fold.
		" zj: Jump to the next fold.
		" zR: Open every fold.
		" zM: Close every fold.
		Plug 'kalekundert/vim-coiled-snake'
		Plug 'konfekt/fastfold'

		" javascript syntax
		Plug 'othree/yajs.vim'

		" yaml use za to toggle fold and zR to expand all
		Plug 'pedrohdz/vim-yaml-folds'

		" https://www.arthurkoziel.com/setting-up-vim-for-yaml/
		" Shows a vertical line for tabs. Great for python and yaml
		Plug 'yggdroot/indentline'

		" For go development
		Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

		" Initialize plugin system
		call plug#end()

		syntax enable

		" don't use all the linters in python, with this list the default uses pylint
		" which doens't work at all and pydocstyle doesn't like markdown in the
		" docstring
		" let g:ale_linters = { 'python' : ['flake8', 'mypy' ] }
		"
		set statusline+=%#warningmsg#
		set statusline+=%*

		set statusline+=%{SyntasticStatuslineFlag()}

		" https://github.com/altercation/vim-colors-solarized
		set background=dark
		" colorscheme solarized  -- for Mac Terminal
		colorscheme solarized8
		" F5 will switch from dark to white
		call togglebg#map("<F5>")

		" https://www.tecmint.com/powerline-adds-powerful-statuslines-and-prompts-to-vim-and-bash/
		set rtp+=/usr/local/lib/python3.8/site-packages/powerline/bindings/vim
		set laststatus=2
		"set t_Co=256

		let g:syntastic_always_populate_loc_list = 1
		let g:syntastic_auto_loc_list = 1
		let g:syntastic_check_on_open = 1
		let g:syntastic_check_on_wq = 1
		let g:syntastic_mode_map = { 'mode' : 'active' }
		" https://raw.githubusercontent.com/scrooloose/syntastic/master/doc/syntastic.txt
		let g:syntastic_id_checkers = 1
		" so we can see which is generating what
		let g:syntastic_sort_aggregate_errors = 1
		" https://github.com/vim-syntastic/syntastic
		" runs each checker in turn, if there are no errors go to the net
		let g:syntastic_javascript_checkers = ['eslint', 'jshint']
		let g:syntastic_yaml_checkers = [ 'yamllint' ]
		" to run a singe check :SyntasticCheck pyflakes
		" https://blog.kartones.net/post/on-python-3-flake8-and-mypy/
		" the default python checker throwing all kinds of errors
		" us mypy first better error detection on literals
		let g:syntastic_python_checkers = [ 'mypy', 'flake8', 'pydocstyle' ]
		" using python 3.3 namespaces to prevent name errors duplicated in .env
		let g:syntastic_python_mypy_args="--namespace-packages"

		" debugging https://github.com/vim-syntastic/syntastic/issues/2282
		" let g:syntastic_debug = 3
		" https://github.com/vim-syntastic/syntastic/issues/204
		" This will slow vim alot as it reads the entire file set
		" https://github.com/vim-syntastic/syntastic/blob/master/doc/syntastic-checkers.txt
		let g:syntastic_rst_checkers = [ 'sphinx', 'rst2pseudoxml' ]
		let g:syntastic_markdown_mdl_exec = "markdownlint"
		let g:syntastic_markdown_mdl_args = ""

		" for shellcheck to source the right file
		let g:syntastic_sh_shellcheck_args = "-x -P SCRIPTDIR"
		au BufRead,BufNewFile *.json set filetype=json

		" Added by install-stylelint.sh on Thu Dec 29 12:20:51 PST 2016
		let g:syntastic_css_checkers = [ 'stylelint' ]
		"
		" https://jaxbot.me/articles/setting-up-vim-for-react-js-jsx-02-03-2015
		let g:jsx_ext_required = 0

		" black line width to be PEP-8
		let g:black_linelength=79

		" https://github.com/dense-analysis/ale
		" Plugins need to be added to runtimepath before helptags can be generated.
		packloadall

		" For indentLine
		" this does not work because indentLine overwrite the conceal
		" if you want to see what is actually happening then
		set conceallevel=2
		set concealcursor=nc
		" you don't expand in normal mode when scrolling but you do when insert
		" this means that you have to be in insert mode to fix markdown
		let g:indentLine_concealcursor = 'nc'
		set foldlevelstart=20

		" Enable latest in markdown file
		let g:vim_markdown_math = 1

		" https://vi.stackexchange.com/questions/6950/how-to-enable-spell-check-for-certain-file-types
		" Turn on spell check for text files
		autocmd FileType md,markdown,txt setlocal spell spelllang=en_us
		autocmd BufRead COMMIT_EDITMSG setlocal spell spelllang=en_us
		" spelling with z=, ]s, [s, zw and zuw
		set spell spelllang=en_us
		set spellfile=~/.vim/spell/en.utf-8.add

		" Turn on NERDTree if there are no files open
		let NERDTreeQuitOnOpen = 1
		autocmd StdinReadPre * let s:std_in=1
		" Open nerdtree if no file is opening
		autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree

		" https://github.com/lifepillar/vim-mucomplete
		set completeopt+=menuone
		" there is no popup.exit anymore
		"inoremap <expr> <c-e> mucomplete#popup_exit("\<c-e>")
		"inoremap <expr> <c-y> mucomplete#popup_exit("\<c-y>")
		"inoremap <expr>  <cr> mucomplete#popup_exit("\<cr>")
		set completeopt+=noselect
		set completeopt+=noinsert
		set shortmess+=c "shut off complete messages
		set belloff+=ctrlg "if vim beeps during completeo
		let g:mucomplete#enable_auto_at_startup = 1
		let g:mucomplete#completion_delay = 0.5 "wait a second before completing

		" Load all of the helptags now, after plugins have been loaded.
		" All messages and errors will be ignored.
		silent! helptags ALL
	EOF
fi
