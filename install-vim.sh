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
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FLAGS="${FLAGS:-""}"
ALIAS="${ALIAS:-false}"
OPTIND=1
while getopts "hdvfa" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install vim plug ins
				flags:
						-h help
					    -d $($DEBUGGING || echo "no ")debugging
					    -v $($VERBOSE || echo "not ")verbose
						-f $($FORCE || echo "no ")force install
					    -a $($ALIAS || echo "no ")set alias as vi
		EOF
		exit 0
		;;
	d)
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		FLAGS+=" -f "
		;;
	a)
		ALIAS="$($ALIAS && echo false || echo true)"
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

# needed for vim-markdown
package_install markdown

"$SCRIPT_DIR/install-solarized.sh"

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
if $ALIAS && ! config_mark; then
	# note we escape the command line so we check the path of vi at run time
	config_add <<-EOF
		if command -v vi >/dev/null; then
			VISUAL="$(command -v vi)"
			export VISUAL
			export EDITOR="$VISUAL"
		fi
	EOF
	log_verbose "source $(config_profile) to enable vi as default editor or relogin"
fi

log_verbose checking .vimrc which should be synced, but if not put in a default
# shellcheck disable=SC2086
if ! config_mark "$HOME/.vimrc" '"'; then
	log_verbose adding to .vimrc
	config_add "$HOME/.vimrc" <<'EOF'
scriptencoding utf-8
" https://www.shell-tips.com/mac/meta-key/
" On a Mac, see :help notation, <C-x> is ⌃X or the control key
" <S-x> is the shift key and `⇧ x`
" <C-x> is the control key `⌃ x`
" <M-x> is done by a two key combination hit ESC and then x
" <D-x> rarely used as it conflicts with the terminal but this is Command ⌘ key
" You can use change this in Terminal or iterm
" :Map shows you all mapping interactively

if !has('nvim')
    let g:data_dir = '~/.vim'
    let g:plugged_dir = '~/.vim/bundle'
else
    let g:data_dir = stdpath('data') . '/site'
    let g:plugged_dir = stdpath('data') . '/plugged'
endif

if empty(glob(g:data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.g:data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  augroup VPLUG
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endif
" https://github.com/junegunn/vim-plug
"if empty(glob('~/.vim/autoload/plug.vim'))
"    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
"      \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
"endif


" - Avoid using standard Vim directory names like 'plugin'
" - Put in the same place as pathogen
" call plug#begin('~/.vim/plugged')
"call plug#begin('~/.vim/bundle')
" https://github.com/junegunn/vim-plug

call plug#begin(g:plugged_dir)

" GitHub Copilot does not run in vim only neovim and vscode
"Plug 'github/copilot.vim'

" Syntax highlights for Solidity
" unmaintained Plug 'tomlion/vim-solidity'
Plug 'thesis/vim-solidity'

" you can find things around quotes with text-object try va"
" cs"'  - change surrounding double quote to single quote
" cst"  - change the surrounding html tag to double quotes
" ds" - delete surround double quotes
" ysis[ - insert brackets around the current sentence
" ysiw" - inserts double quotes around a word (fail randomly some interaction)
" vf.S[ - go to visual mode, find the next period, Subsitute around it brackets
"Plug 'tpope/vim-surround'
"
" alternative to vim-surround
" sa{motion/textobject}{addition} - saiw( sandwich add insert word ()
" sdb - delete surround character
" sd{deletion} - deletion a specific surround character
" srb{addition} - sandwich replace the surrounding - srb( replaces parensd
" sr{deletion}{addition} - sandwidth replace around the movement
Plug 'machakann/vim-sandwich'

" Using mermaid for sequence and viewing markdown
" Thanks to Wowchemy for pointer
" https://github.com/xavierchow/vim-sequence-diagram
" enabled with .seq files, start with <leader>t
" Supports mermaid syntax based on vim-sequaence-diagram
" this does not seem to work so cannot get mermaid preview in .seqa
"Plug 'zhaozg/vim-diagram'
" This only handles sequecne diagrams in UML
" https://github.com/bramp/js-sequence-diagrams
" :Graphviz! jpg create the jpg and open it for the corresponding dot file
Plug 'liuchengxu/graphviz.vim'
" Tagbar that learns from LSP servers
Plug 'liuchengxu/vista.vim'

" Python specific text objects, classes, functions
Plug 'jeetsukumaran/vim-pythonsense'


" Python syntax highlighting (can also use sheerun/vim-polyglot)
" https://github.com/numirias/semshi/issues/59
Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }

" https://github.com/zhaozg/vim-diagram
" for .seq files then \t brings up a windo and shows you the diagram
" doe not seem to and not enough files
"Plug 'zhaozg/vim-diagram'

" in a .md file Ctrl-p will preview which looks really ugly use iamcco instead
"Plug 'jamshedvesuna/vim-markdown-preview'
" https://github.com/iamcco/markdown-preview.nvim
" :MarkdownPreview starts and then :MarkdownPreviewStop to end
" can visualize katex, mermaid, js-sequence-diagms, flowchart
" does not work no command tslib not found on M1
"Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }, 'for': ['markdown', 'vim-plug']}
" does require a clean comtimes or :PlugInstall! to work
Plug 'iamcco/markdown-preview.nvim', { 'do':  'cd app && yarn install' }

Plug 'godlygeek/tabular'
Plug 'preservim/vim-markdown'

" <C-X><C-E> For directly entering emojis where you want the Unicode character
Plug 'kyuhi/vim-emoji-complete'

" https://junegunn.kr/2014/06/emoji-completion-in-vim/
" C-X/C-U to get the gitmoji :boom: and see how it translates
" So you get text and works when UTF-8 is not available.
Plug 'junegunn/vim-emoji'
" focus on paragraph
Plug 'junegunn/limelight.vim'
Plug 'junegunn/goyo.vim'
" fzf - fuzzy find with auto update of fzf
" :Files [PATH] all files from PATH
" :GFiles git ls-files
" :Rg [PATTERN] run ripgrep
" :Marks :Windows
" Ctrl-t for new tab, Ctrl-x new split Ctrl-v vertical split
Plug 'junegunn/fzf', { 'do' : {-> fzf#install() }}
Plug 'junegunn/fzf.vim'
"
" Syntax highlights for Solidity
" unmaintained Plug 'tomlion/vim-solidity'
Plug 'thesis/vim-solidity'
" <C-X><C-E> For directly entering emojis where you want the Unicode character
Plug 'kyuhi/vim-emoji-complete'

" Use this for xterm2
Plug 'lifepillar/vim-solarized8'

" Using Powerline instead but then it broke so back again to vim-airline
" https://www.tecmint.com/powerline-adds-powerful-statuslines-and-prompts-to-vim-and-bash/
" better status line that is vim only
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

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
" The ge and [[ don't seem to work here ]]
" gg - First line of file
" ge - go to from cursor to end of previous word
" G - last line of file
" nG - Go to line number n
" ]] - next header, [[ previous header,
" ]c - go to current header, [u go to parent
" For Markdown files via vim-markdown
" zr: fold reduce, zR: open all folds, zm: increase folding, za: open fold at cursor
" turn off the insert mode so that you can see the urls with se cole=0
" vim-polyglot includes this
" let g:vim_markdown_math to enable Latex
Plug 'sheerun/vim-polyglot'

" No longer maintained switched to a fork
" Plug 'jiangmiao/auto-pairs'
" <CR> return inserts a new indented line with indenting for {}
" <BS> Backspace deletes the pair of brackets or parents
" default is the first since cannot get <M-p> to work on a Mac
" <C-p><C-t> or <M-p> Toggle autopairs.
" <C-f> and not <M-e> Fast wrap when in insert mode, wraps word that follow
" <C-p><C-s> and not <M-n> Jump to next closed pair
" <C-p><C-b> or <M-m> back inserts not used if flymode is off recommended
" https://github.com/LunarWatcher/auto-pairs
Plug 'LunarWatcher/auto-pairs', { 'tag' : '*' }

" 5\ci inverts a comment for next 5 lines
" 5\cc comment out 5 lines
" 5\c<space> togles, so if top is commented, all the rest are uncommented
" 5\cn comment out with nexting the next 5 lines
" 5\cm comment out the next 5 lines with multi part deliminator
" 5\cs sexy comment that is as a block comment
" \c space inverts the entire block
" Need let g:NERDDefaultAlign = 'left' so mypy likes the comments
Plug 'preservim/nerdcommenter'

" Git in vi with :G commit,:G diff, :G difftool, :Gdiffsplit
Plug 'tpope/vim-fugitive'
" Git signs in the gutter
Plug 'airblade/vim-gitgutter'

" directory level version of vimdiff or vim -d <file1> <file2>
" https://www.tutorialspoint.com/vim/vim_diff.htm
" https://github.com/will133/vim-dirdiff
" :DirDiff <dir1> <dir2>
" vi -c "DifDiff dir1 dir2""
Plug 'will133/vim-dirdiff'

" Python indenting
Plug 'vimjas/vim-python-pep8-indent', { 'for': 'python' }
" :Black to run the python reformatter
" If you get a black not found, rm ~/.vim/black and do a BlackUpgrade
" there is no more stable branch
"Plug 'psf/black', {'branch': 'stable'}
Plug 'psf/black', { 'for': 'python' }

" This is not needed with neovim and coc.nvim
" Python folding
" http://vimdoc.sourceforge.net/htmldoc/fold.html#zf
" zo: Open a fold at cursor
" zc: Close a fold at cussor
" za: toggle folding at cursor
" zO: Open all folds at cursor
" zC: Close all folds at curosr
" zA: Toggle all folds at curosr
"
" zr: reduce folds by one (that is open) in entire buffer
" zm: more folding (that is closed) in entire buffer
" zR: Reduce all folds (that is completely open) in entire buffer
" zM: Most folds (that is totally closed) in entire buffer
"
" zn: no folding
" zN: normal folding (turn it on)
" zi: invert folding
"
" [z: go to previous open fold
" ]z: next open fold
" zk: move up a fold
" zj: move down a fold
Plug 'kalekundert/vim-coiled-snake', { 'for': 'python' }
Plug 'konfekt/fastfold', { 'for': 'python' }

" Typescript syntax highlighting on by default https://github.com/Quramy/tsuquyomi
" Insert mode C-X C-O completion with omnicompletion
" C-] go to definition, C-t go back
" C-^ find reference
" :TsuTypeDefinition to go to the type source
Plug 'Quramy/tsuquyomi', { 'for': 'typescript' }

" Json syntax highlighting, conceals double quotes
" add folding with ftpluging/json.vim adding foldmethod=syntax
Plug 'elzr/vim-json', { 'for': 'json' }


" za toggle fold, zR expand all folds, zo open fold,
" zM close all folds
Plug 'tmhedberg/simpylfold'

" javascript syntax
Plug 'othree/yajs.vim', { 'for': 'javascript' }

" yaml use za to toggle fold and zR to expand all
Plug 'pedrohdz/vim-yaml-folds', { 'for': ['yaml' , 'githubaction']}

" https://www.arthurkoziel.com/setting-up-vim-for-yaml/
" Shows a vertical line for tabs. Great for python and yaml
Plug 'yggdroot/indentline'

" https://thoughtbot.com/blog/writing-go-in-vim
" For go development run :GoInstallBinaries
" :GoBuild, :GoInstall, :GoTest
" :GoTestFunc to run a single function
" :GoRun, :GoDebugStart
" :Godef Goto declaration
" :GoImport [path] adds the path
" :GoImportAs [name] [path]
" :GoDrop [path] removes the import
" :GoImports go the file
" :GoFmt autoformatst eh file defaults on save
" :GoDoc [package] or look up under the cursor
" :GoRename a variable
" :GoCoverage
" :GoLint
" :GoVet for static errors
" :GoImplements, :GoCallees, :GoReferrers
" <C-x><C-p> auto completion while in edit mode
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

if has('nvim')
    Plug 'overcache/NeoSolarized'
else
    " colorscheme tuned for Mac Terminal
    Plug 'altercation/vim-colors-solarized'
endif

" With neovim use copilot and ale, syntastic with vim since synchronouse
" and the completion uses mucomplete
if has('nvim')
    Plug 'shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }

    " Asychronous (the point of neovim) multi-language linting
    " :ALEInfo for available linters :ALEFix to let YAPF fix it
    " ALE, Syntastic and Coc all compete, have overlapping features
    " So use ALE for shellcheck, but Coc for languages
    " :ll for first errors kept in the location list
    " :lnext for next error
    " :lp for previous error
    Plug 'dense-analysis/ale'

    " Completion using a floating window, neovim only
    " https://stackoverflow.com/questions/69295405/nvim-with-coc-and-formatting-for-python
    " must manally run :CocInstall coc-jedi coc-json
    " All these need to be manually enabled all bindings below
    " No longer neede using copilot instead
    "Plug 'neoclide/coc.nvim', {'branch': 'release'}

    " GitHub Copilot does not run in vim only neovim and vscode
    Plug 'github/copilot.vim'

else
    " for regular vim no Copilot and ale and coc/deoplete are slow async
    " use syntastic for errors because it is synchronous and fast
    " mucomplete for completions instead instead of Copilot

    "not using deoplete with vim too slow
    "Plug 'Shougo/deoplete.nvim'
    "Plug 'roxma/nvim-yarp'
    "Plug 'roxma/vim-hug-neovim-rpc'

    " Linter that is synchronous but works well, better than COC
    " less lag with vim
    " Puts errors into the location list
    " :lab location above cursor, :lbel location below cursor
    " :lbe location before cursor, :laf location after cursor
    " :ll currrent loc, :lne next loc, :lp previous,
    " :lN next file, :lp previous file
    " :lnf next file, :lpf or :pNf preivous file
    " :lr or :lfir goto error default is first error, :las last error
    " :l
    Plug 'vim-syntastic/syntastic'
    " https://protofire.github.io/solhint/
    " Solhint as solc does not syntax check
    Plug 'sohkai/syntastic-local-solhint'

    " Shell formatting run with :Shfmt
    Plug 'z0mbix/vim-shfmt', { 'for': 'sh' }

    " vim-mucomplete during insert find completions based on path, omni, buffer
    " words, dictionary or spelling
    " https://github.com/lifepillar/vim-mucomplete
    " jedi-vim for python, clang-complete for C
    " set completeopt and others to get it to work
    " C-h cancel menu and try a different completer
    " C-j pick next completer
    " <tab> or shift-tab to change
    " Generating a startup error so disable
    Plug 'lifepillar/vim-mucomplete'
    " Python syntax used with vim-mucomplete, and has complete language
    " <c-space> to complete
    " K for documentation  \g goto
    " \d find definition across imports  \s create a stub
    " \r rename a variable, \n for usages
    " Incompatible with python-mode
    " With neovim, use coc.nvim or deoplete-jedi instead for async
    Plug 'davidhalter/jedi-vim'

endif


call plug#end()

" modelines are a security hole but worthwhile for css files that like 2 indents
" Tuned for python
" For indentLine
" this does not work because indentLine overwrites the conceal
" if you want to see what is actually happening then
" you don't expand in normal mode when scrolling but you do when insert
" this means that you have to be in insert mode to fix markdown
" If you want to edit markdown, the set conceallevel=0
set autoread
set background=dark
set concealcursor=nc
set conceallevel=2
set expandtab
set foldlevelstart=20
set incsearch
set modeline
set number relativenumber  " numbers are ugly  but needed for Python
set shiftwidth=4
set showmatch
set spell spelllang=en_us " Turn on spell check for text files
set tabstop=4
set textwidth=79

syntax enable

set statusline+=%#warningmsg#
set statusline+=%*
set statusline+=%{SyntasticStatuslineFlag()}

" colorscheme solarized  -- for Mac Terminal calls altercation
" solarized8 is more modern handles 256-colors
if has('nvim')
    colorscheme NeoSolarized
else
    colorscheme solarized8
    " F5 will switch from dark to white
    call togglebg#map('<F5>')
endif

let g:deoplete#enable_at_startup = 1

" enable images preview with markdown  on Ctrl-P
let vim_markdown_preview_toggle=1
"set t_Co=256

" https://stackoverflow.com/questions/34428944/how-to-enable-gx-in-vim-mine-doesnt-work-anymore
" https://github.com/vim/vim/issues/4738
" https://stackoverflow.com/questions/9458294/open-url-under-cursor-in-vim-with-browser
" This is broken right now as of Jan 7 2021 waiting for a PR but it downloads
" the URL contents and then runs the default editor for gx
" gx - opens the link under the cursor (not the default gx opens a brownser)
" https://vim.fandom.com/wiki/Open_file_under_cursor
" gf - open the filename under the cursor in vim itself
" <c-w>f - open filename in a new window
" <c-w>gf opens in a new tab
let g:netrw_browser_viewer ='open'
let g:netrw_browsex_viewer ='open'

"so mypy likes the comments
let g:NERDDefaultAlign = 'left'

if has('nvim')
    " ALE status line
    let g:airline#extensions#ale#enabled = 1

    " ALE opens the location list if more than 5 entries
    let ale_open_list=5

    " github actions are yaml files so pick up their behaviors'
    let g:ale_linter_aliases = {
        \ 'githubaction' : ['yaml'],
    \ }
    " By default ALE uses all linters simultaneously so only do this if you do
    " python: exclude pylint which does not work at all
    " yaml: add actionlint for github action not enabled by default
    " the options below aren't needed, what is an executable is run
    " yaml disable things like actionlint since github do not have their own
    " unique .yaml extension
        "\ 'sh' : ['shellcheck'],
        "\ 'html' : ['htmlhint'],
        "\ 'javascript' : ['eslint', 'jshint'],
        "\ 'css' : ['csslint'],
        "\ 'markdown' : ['markdownlint'],
        "\ 'vim' : ['vint'],
    let g:ale_linters = {
        \ 'python' : ['flake8', 'mypy', 'pydocstyle' ],
        \ 'yaml' : ['yamllint'],
        \ 'githubaction' : ['actionlint'],
    \ }

    " actually change code with linter
    "'trim_whitespace' - Remove all trailing whitespace characters at the end of every line.
    "'remove_trailing_lines' - Remove all blank lines at the end of a file.
    "'add_blank_lines_for_python_control_statements' - Add blank lines before control statements.
    "'autoflake' - Fix remove ununsed imports and variables with pyflakes
    "'autoimport' - remove unused imports and add new ones.
    "'isort' - Sort Python imports and reorder
    "'reorder-python-imports' - Sort Python imports with reorder-python-imports.
    " Conflicting format fixers using black now
    "'autopep8' - Fix PEP8 issues with autopep8.
    "'yapf' - Fix Python files with yapf. conflict with black
    "'black' - Fix PEP8 issues with black.
    let g:ale_fixers = {
        \ '*': ['remove_trailing_lines', 'trim_whitespace'],
        \ 'python': [ 'black', 'isort', 'autoimport' ],
        \ 'javascript': ['eslint'],
        \ 'sh': ['shfmt'],
    \}

    " No long need CoC using GitHub Copilot
    " https://github.com/neoclide/coc.nvim/issues/560
    " coc-highlight - highlight symbol when there is no language server
    " coc-vimtex - Latex completions
    " coc-github-ussers - completion for github commits
    " https://github.com/iamcco/coc-diagnostic
    " coc-diagnostic - for linters not included by default like markdown
    " set in coc-settings.json
    " Allow ALE and coc.nvim to work together not needed since we use ALE with
    " Copilot on neovim and Syntastic with mucomplete in vim
    " https://github.com/dense-analysis/ale
    " coc.settings.json add diagnostic.displayByAle
    " let g:ale_disable_lsp = 1
    "let g:coc_global_extensions = [
    "    \ 'coc-markdownlint',
    "    \ 'coc-python',
    "    \ 'coc-flutter',
    "    \ 'coc-json',
    "    \ 'coc-yaml',
    "    \ 'coc-html',
    "    \ 'coc-vimtex',
    "    \ 'coc-github-users',
    "    \ 'coc-python',
    "    \ 'coc-diagnostic',
    "    \ 'coc-git']
    " https://github.com/neoclide/coc.nvim/issues/353
    "call coc#add_extension(coc_global_extensions)


    " To use in a virtual environment need to create a .vim
    " https://github.com/neoclide/coc-python/issues/20
    " The default global configuration
    " https://www.reddit.com/r/neovim/comments/ffnil1/help_configuri ng_cocnvim_extension_settings/
    " Access with :CocConfig or the directory specific at :CocLocalConfig
    " config.path('config') . 'coc-settings.json'
    " Now the huge list of CoC commands from here on
    " Note you need a coc-setting.json here
    " And for python, need to set a .env with PYTHONPATH=.
    " and then add the search for it
    " https://github.com/neoclide/coc-python/issues/108
    " https://vi.stackexchange.com/questions/25076/coc-python-reports-unresolved-import-in-git-subfolder
    "augroup COC
    "  autocmd FileType python let b:coc_root_patterns = ['.git', '.env', '.hg']
    "augroup END
    " <tab> - move down the completion list, <shift-tab> to move up
    " <cr> - confirm the completion, after you select it
    " ctrl-<space> - list completions (also happens by default after 300ms)
    " ]g  - Go to next lint error
    " ]g  - Go to previous lint error
    " gd  - Go to where variable is first defined
    " gi  - Go to the implementation of a call
    " gr - Go to all references of a variable
    " To run the Microsoft Python Language Server
    " in coc-setting.json { "python.jediEnabled" : false}
    " Add these are are in a separate file

else

    let g:syntastic_always_populate_loc_list = 1
    let g:syntastic_auto_loc_list = 1
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 1
    let g:syntastic_mode_map = { 'mode' : 'active' }
    " you must enable syntastic checkers by supplying a list
    " in the form of let g:syntastic_<filetype>_checkers = ['<checker-name>'
    let g:syntastic_vim_checkers = [ 'vint' ]
    " solc does not seem to lint correctly
    let g:syntastic_solidity_checkers = [ 'solhint', 'solc']
    " https://raw.githubusercontent.com/scrooloose/syntastic/master/doc/syntastic.txt
    let g:syntastic_id_checkers = 1
    " so we can see which is generating what
    let g:syntastic_sort_aggregate_errors = 1
    " https://github.com/vim-syntastic/syntastic
    " Disable syntastic built in tsc checker and use tsuquyomi
    let g:syntastic_typescript_checkers = ['tsuquyomi']
    " runs each checker in turn, if there are no errors go to the net
    let g:syntastic_javascript_checkers = ['eslint', 'jshint']
    let g:syntastic_yaml_checkers = [ 'yamllint', 'hadolint' ]
    " to run a singe check :SyntasticCheck pyflakes
    " https://blog.kartones.net/post/on-python-3-flake8-and-mypy/
    " the default python checker throwing all kinds of errors
    " us mypy first better error detection on literals
    let g:syntastic_python_checkers = [ 'mypy', 'flake8', 'pydocstyle' ]
    " using python 3.3 namespaces to prevent name errors duplicated in .env
    let g:syntastic_python_mypy_args='--namespace-packages'
    " Restructure text or sphinx output
    let g:syntastic_rst_checkers = [ 'sphinx', 'rst2pseudoxml' ]
    " debugging https://github.com/vim-syntastic/syntastic/issues/2282
    " let g:syntastic_debug = 3
    " https://github.com/vim-syntastic/syntastic/issues/204
    " This will slow vim alot as it reads the entire file set
    " https://github.com/vim-syntastic/syntastic/blob/master/doc/syntastic-checkers.txt
    " switch to markdownlint-cli for node.js since it
    " has disabling in line
    "let g:syntastic_markdown_mdl_exec = "mdl"
    " https://github.com/vim-syntastic/syntastic/blob/master/doc/syntastic-checkers.txt
    let g:syntastic_markdown_mdl_exec = 'markdownlint'
    let g:syntastic_markdown_mdl_args = ''
    " add shfmt to do formatting as well but this causes suprious errors just use
    " for formatting
    " let g:syntastic_sh_checkers = ["shellcheck", "shfmt"]
    " for shellcheck to source the right file
    let g:syntastic_sh_shellcheck_args = '-x -P SCRIPTDIR'
    " add shfmt to do formatting as well but this causes suprious errors just use
    " for formatting
    " let g:syntastic_sh_checkers = ["shellcheck", "shfmt"]
    " for shellcheck to source the right file
    let g:syntastic_sh_shellcheck_args = '-x -P SCRIPTDIR'
    " Added by install-stylelint.sh on Thu Dec 29 12:20:51 PST 2016
    let g:syntastic_css_checkers = [ 'stylelint' ]

    " https://github.com/lifepillar/vim-mucomplete
    set completeopt+=menuone
    " there is no popup.exit anymore
    "inoremap <expr> <c-e> mucomplete#popup_exit("\<c-e>")
    "inoremap <expr> <c-y> mucomplete#popup_exit("\<c-y>")
    "inoremap <expr>  <cr> mucomplete#popup_exit("\<cr>")
    set completeopt+=noselect
    "set completeopt+=noinsert
    set shortmess+=c "shut off complete messages
    set belloff+=ctrlg "if vim beeps during complete
    let g:mucomplete#enable_auto_at_startup = 1
    " Note this must be an integer
    let g:mucomplete#completion_delay = 1
endif

" https://jaxbot.me/articles/setting-up-vim-for-react-js-jsx-02-03-2015
let g:jsx_ext_required = 0
let g:tsuquyomi_disable_quickfix = 1

" https://vi.stackexchange.com/questions/9455/why-should-i-use-augroup
augroup vimenter
  autocmd!
  autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
      \| PlugInstall --sync | source $MYVIMRC
  \| endif
augroup END

" \e to rename a variable, \E rename in comments too, but there is no \t tooltip
augroup typescript
  autocmd!
  autocmd FileType typescript nmap <buffer> <Leader>e <Plug>(TsuquyomiRenameSymbol)
  autocmd FileType typescript nmap <buffer> <Leader>E <Plug>(TsuquyomiRenameSymbolC)
"autocmd FileType typescript nmap <buffer> <Leader>t : <C-u>echo tsuquyomi#hint()<CR>
augroup END

" $VIMRUNTIME/filetype.vim for file type by extension
" $VIMRUNTIME/scripts.vim for file type by contents
" for things like YAML which has multiple types use a modeline or name it like
" this
" /* vi: set ft=githubaction */
augroup githubaction
  autocmd!
  autocmd BufRead,BufNewFile workflow.*.yaml,*.workflow.yaml,*.gha.yaml set ft=githubaction
  autocmd BufRead,BufNewFile workflow.*.yml,*.workflow.yml,*.gha.yml set ft=githubaction
augroup END

"this is already done by default so comment out
"augroup json
"  autocmd!
"  autocmd BufRead,BufNewFile *.json set filetype=json
"augroup END

" https://vi.stackexchange.com/questions/6950/how-to-enable-spell-check-for-certain-file-types
" Turn on spell check for markdown and text files
augroup md
  autocmd!
  autocmd FileType md,markdown,txt setlocal spell spelllang=en_us
  autocmd BufRead COMMIT_EDITMSG setlocal spell spelllang=en_us
augroup END

" Setup file specific stuff
" https://vi.stackexchange.com/questions/6950/how-to-enable-spell-check-for-certain-file-types
augroup FILE
  " https://www.arthurkoziel.com/setting-up-vim-for-yaml/
  autocmd FileType yaml setlocal tabstop=2 sts=2 shiftwidth=2 expandtab
  " something is etting this to yaml
  autocmd FileType sh setlocal tabstop=4 sts=2 shiftwidth=4 expandtab
augroup END
"
" Turn on NERDTree if there are no files open
let NERDTreeQuitOnOpen = 1
augroup NERD
  autocmd!
  autocmd StdinReadPre * let s:std_in=1
  " Open nerdtree if no file is opening
  autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree
augroup END

" Turn on NERDTree if there are no files open
let NERDTreeQuitOnOpen = 1
augroup NERD
  autocmd!
  autocmd StdinReadPre * let s:std_in=1
  " Open nerdtree if no file is opening
  autocmd VimEnter * if argc() == 0 && !exists("s:std_in") | NERDTree
augroup END

" black line width to be PEP-8
let g:black_linelength=79

" https://github.com/dense-analysis/ale
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall

" For indentLine
" this does not work because indentLine overwrites the conceal
" if you want to see what is actually happening then
set conceallevel=2
set concealcursor=nc
" you don't expand in normal mode when scrolling but you do when insert
" this means that you have to be in insert mode to fix markdown
" If you want to edit markdown, the set conceallevel=0
let g:indentLine_concealcursor = 'nc'
" https://github.com/overcache/NeoSolarized
" get a lighter char for looking at indent
let g:indentLine_char = '⦙'
set foldlevelstart=20

" Enable latest in markdown file
let g:vim_markdown_math = 1
let g:vim_markdown_strikethrough = 1
" Used by hugo
let g:vim_markdown_toml_frontmatter = 1
let g:vim_markdown_json_frontmatter = 1
let g:vim_markdown_frontmatter = 1
" enable images preview with markdown  on Ctrl-P

" spelling with z=, ]s, [s, zw and zuw
set spell spelllang=en_us
set spellfile=~/.vim/spell/en.utf-8.add

" https://medium.com/usevim/vim-101-completion-compendium-97b4ebc3a45a
" With Omnicompletion When in insert mode automatically started with mucompletion
" C-N find a work like this next word like this in the buffer
" C-P find a line like this one from previous
" C-X C-L complete an entire line
" C-X C-K dictionary look for similar words
" C-X C-O language specific completion
" C-X C-N next word
filetype plugin on
set omnifunc=syntaxcomplete#Complete

" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL

" Enable Emoji command completion
set completefunc=emoji#complete

" use <C-x> instead of <M-p> which does not work on MacOS
let g:AutoPairsCompatibleMaps = 0

" for Go https://jogendra.dev/using-vim-for-go-development
let g:go_highlight_fields=1
let g:go_highlight_functions=1
let g:go_highlight_function_calls=1
let g:go_highlight_extra_types=1
let g:go_highlight_operators=1
let g:go_fmt_autosave=1
let g:go_fmt_command='goimports'

" Added by install-powerline.sh on Fri Mar 26 10:50:44 PDT 2021
" Add in Plug Begin
" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
let g:airline#extensions#tabline#enabled = 1

" Notes on using vimdiff
" https://unix.stackexchange.com/questions/52754/whats-the-recommended-way-of-copying-changes-with-vimdiff
" ]c - next block of differences
" [c - previous block
" do - obtain changes from other file and put in current buffer
" dp - put changes from this file into the other buffer
" zo - open the fold, zc close fold, zr unfold completely, zm fold both

" https://github.com/preservim/nerdcommenter
" enables \c} comment to next paragraph
" \c{ comment to previous paragraph
" doe not work
nnoremap <silent> <leader>c} V}:call NERDComment('x', 'toggle')<CR>
nnoremap <silent> <leader>c{ V{:call NERDComment('x', 'toggle')<CR>

" https://duseev.com/articles/vim-python-pipenv/
" switch environments depending on pipenv
let pipenv_venv = system('pipenv --venv')
if v:shell_error == 0
   let venv_path = substitute(pipenv_venv, '\n', '', '')
   let g:python3_host_prog = venv_path . '/bin/python'
else
   let g:python3_host_prog = 'python'
endif

" light color for limelight
let g:limelight_conceal_ctermfg = 240

" https://vi.stackexchange.com/questions/8244/how-to-clear-previous-search-highlight-in-vim
" map CTRL-L to clear search highlight and redraw
nnoremap <C-l> :nohlsearch<CR><C-L>

EOF
fi
