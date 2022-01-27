#!/usr/bin/env bash
#
# neovim inpsired by python specific fixes
# https://www.vimfromscratch.com/articles/vim-for-python/
# https://hanspinckaers.com/posts/2020/01/vim-python-ide/
#
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
		cat <<-EOF
			Install newvim with all the plugins

			flags: -d debug, -v verbose, -h help
		EOF
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
# https://github.com/hadolint/hadolint/issues/343
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-config.sh

brew_install neovim

log_verbose "get neovim python packages in system python"
log_warning "All pipenv installation need this in the python world"
pip_install neovim

log_verbose install IDE tools
"$SCRIPT_DIR/install-lint.sh"

log_verbose "create vi as alias for nvim and set git to use it"
if ! config_mark; then
	config_add <<-EOF
		alias vi=nvim
		export VISUAL=nvim
		export EDITOR="$VISUAL"
	EOF
fi
git config --global core.editor "nvim"

# https://wiki.archlinux.org/index.php/Neovim
# you cannot use a tilde here readlink does not like it in lib-config
NVIM_CONFIG="${NVIM_CONFIG:-"$HOME/.config/nvim"}"
log_verbose "creating $NVIM_CONFIG"
mkdir -p "$NVIM_CONFIG"

# https://www.linode.com/docs/tools-reference/tools/how-to-install-neovim-and-plugins-with-vim-plug/
# https://www.reddit.com/r/neovim/comments/3z6c2i/how_does_one_install_vimplug_for_neovim/
NVIM_INIT="${NVIM_INIT:-"$NVIM_CONFIG/init.vim"}"
log_verbose "creating $NVIM_INIT"
if ! config_mark "$NVIM_INIT" '"'; then
	log_verbose "creating $NVIM_INIT"
	config_add "$NVIM_INIT" <<-EOF
		" check for vim-plug install if needed
		" https://github.com/junegunn/vim-plug/issues/739
		let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
		if empty(glob(data_dir . '/autoload/plug.vim'))
		  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
		  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
		endif

		" vim-plug
		call plug#begin(stdpath('config') . '/plugged')

		" Navigate directory tree
		Plug 'scrooloose/nerdtree'

		" Fuzzy search for files
		Plug 'junegunn/fzf.vim'

		" Press gcc to comment out a line or gc for visual mode
		Plug 'scrooloose/nerdcommenter'

		" Tagbar that learns from LSR serviers
		Plug 'liuchengxu/vista.vim'

		" Python specific text objects, classes, functions
		Plug 'jeetsukumaran/vim-pythonsense'

		" Insert closing quotes and parens as you type
		Plug 'jiangmiao/auto-pairs'

		" Ugly! Atom inspired color scheme or junngunn/seoul256.vim
		" "Plug 'joshdick/onedark.vim'
		" does not work
		" Plug 'frankmer/neovim-colors-solarized-truecolors'

		" make sure to set termguicolors ; colorscheme NeoSolarized
		Plug 'overcache/neosolarized'

		" syntax highlighting (can also use sheerun/vim-polyglot)
		" https://github.com/numirias/semshi/issues/59
		Plug 'numirias/semshi', { 'do': ':UpdateRemotePlugins' }

		" Python indenting
		Plug 'vimjas/vim-python-pep8-indent'

		" Asychronous (the point of neovim) multi-language linting
		" :ALEInfo for available linters :ALEFix to let YAPF fix it
		" I normally use syntastic, don't use both
		Plug 'dense-analysis/ale'

		" Interface to jedi (use coc instead) for code completion
		" \d to definition, \g to assignment, \s goto stub, K for documentation
		" \r to rename variable, \n all name usages
		" https://stackoverflow.com/questions/1764263/what-is-the-leader-in-a-vimrc-file
		Plug 'davidhalter/jedi'

		" Completion using a floating window, neovim only the curring edge
		" must manally run :CocInstall coc-python coc-json
		Plug 'neoclide/coc.nvim', {'branch': 'release'}

		" Run :Git inside vim or :G
		Plug 'tpope/vim-fugitive'

		" vim status line (pretty ugly)
		Plug 'vim-airline/vim-airline'
		Plug 'vim-airline/vim-airline-themes'

		" https://www.arthurkoziel.com/setting-up-vim-for-yaml/
		" Show a thin line for indents
		Plug 'yggdroot/indentline'
		" za toggle fold, zR expand all folds, zo open fold, zM close all
		Plug 'pedrohdz/vim-yaml-folds'
		Plug 'tmhedberg/simpylfold'

		call plug#end()

		" https://github.com/overcache/NeoSolarized
		set termguicolors
		set background=dark
		colorscheme NeoSolarized
		" get a lighter char for looking at indent
		let g:indentLine_char = '⦙'
		" everything starts unfolded
		set foldlevelstart=20
		" Default to make sure tabs work and use python pep8 width
		set shiftwidth=4 expandtab tabstop=4 wrapmargin=79
		set number

		" give it the linter list you use taken from rich's .vimrc
		let g:ale_linters = {
		    \ 'python' : ['mypy', 'flake8', 'pydocstyle', 'pylint'],
		    \ 'javascript' : ['eslint', 'jshint'],
		    \ 'yaml' : ['yamllint']
		\ }
		" actually change code with linter
		let g:ale_fixers = {
		    \ 'python': ['yapf'],
		\}

		au BufNewFile,BufRead *.py set foldmethod=indent

		" https://github.com/neoclide/coc.nvim/issues/560
		" coc-highlight - highlight sysmbol when there is no language server
		" coc-vimtex - Latex completions
		let g:coc_global_extensions = [
		    \ 'coc-markdownlint',
		    \ 'coc-python',
		    \ 'coc-flutter',
		    \ 'coc-json',
		    \ 'coc-yaml',
		    \ 'coc-html',
		    \ 'coc-vimtex',
		    \ 'coc-git']

		" https://github.com/neoclide/coc.nvim
		" needs full mapping to get all features
		nmap <leader>rn <Plug>(coc-rename)
		nmap <leader>f <Plug>(coc-format-selected)
		xmap <leader>f <Plug>(coc-format-selected)

		" https://duseev.com/articles/vim-python-pipenv/
		" switch environments depending on pipenv
		let pipenv_venv = system('pipenv --venv')
		if v:shell_error == 0
		   let venv_path = substitute(pipenv_venv, '\n', '', '')
		   let g:python3_host_prog = venv_path . '/bin/python'
		endif

	EOF
fi
