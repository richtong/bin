#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install Zsh
## https://phuctm97.com/blog/zsh-antigen-ohmyzsh
## https://www.viget.com/articles/zsh-config-productivity-plugins-for-mac-oss-default-shell/
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
# do not need To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# trap 'exit $?' ERR
OPTIND=1
CHSH="${CHSH:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvc" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Zsh
			    usage: $SCRIPTNAME [ flags ]
				flags: -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
				-c change default shell (default: $CHSH)
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;;
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	c)
		CHSH=true
		;;
	*)
		echo "not flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-util.sh lib-config.sh lib-install.sh

brew_install zsh zinit
# install these with zinit so we don't have to add source
#zsh-autosuggestion zsh-syntax-highlighting

log_verbose "Add homebrew zsh to /etc/shells"
ZSH_PATH="$(brew --prefix)/bin/zsh"
config_add_shell "$ZSH_PATH"

if $CHSH; then
	log_verbose "Change default shell to zsh"
	config_change_default_shell "$ZSH_PATH"
fi

log_verbose "Adding Oh My Zsh"
# https://osxdaily.com/2021/11/15/how-install-oh-my-zsh-mac/
if [[ ! -e $HOME/.oh-my-zsh ]]; then
	log_verbose "Install On My Zsh"
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# https://travis.media/top-10-oh-my-zsh-plugins-for-productive-developers/
# from @atong suggestions and https://travis.media/top-10-oh-my-zsh-plugins-for-productive-developers/

PACKAGE+=(
	pygments
	autojump
)
log_verbose "Install Package ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

log_verbose "The F*ck requires special install"
./install-thefuck.sh

log_verbose "Adding OMZ plugins"
log_verbose "Pygment syntax highlighter must be linked"
brew link pygments
log_verbose "Install fzf after vi-mode as the Ctrl-R conflict"

# deprecated
# btrestart - restart bluetooth
# pushdf - push finder dir, showfiles - sho hidden in Finder
# ipfs
# ubuntu - acs apt-cache search
# pipenv pcl is pipenv clean prun and psh and psy for sync
# ubuntu
# azure  # completions
PLUGIN+=(
	vi-mode # vi-mode overwrites ^r so it must come before fzf

	1password    # opswd wraps the op command so opswd github will put your us
	alias-finder # if there is an alias for a command it suggests it
	aliases      # acs shows all alias by group
	# asdf            # asdf - completions and also shims deprecated by asdf direnv
	autojump          # autojump - j does a fuzzy search for a directory complements warp
	aws               #completions
	bgnotify          # baackground notify
	brew              # bubo brew update & brew outdated bubc brew update && brew
	chezmoi           # completions
	colored-man-pages # colored-man-pages - make man pages look nice
	colorize          # colorize - uses pygmenter to ccat files in color
	command-not-found # suggestions
	common-aliases    # l ls -lFh h history ff find . -type f -name hgrep
	conda             # aliases
	copybuffer        # Ctrl-O to copy current text to the clipbard
	copyfile          # puts the contents of the file to your clipboard
	copypath          # copy the last path onto clipboard
	dircycle          # cycle through the last 10 directories with CTRL-SHIFT ⬅️ and ➡️
	direnv            # hook
	dirhistory        # dirhistory - ALT-Left goes to previous directory, ALT-right so like dirs (does not work with AnnePro2)
	docker            # docker - completions and aliases like dbl for docker build
	docker-compose    # docker-compose - completions and alias
	doctl             # doctl - digital ocean command completions
	emoji             # emoji - echo $emoji[mouse_face] works or juse Mac emojify to get :smile:
	emoji-clock       # emoji-clock - emoji not characters for clock
	encode64          # encode64 - alias like e64
	extract           # extract - general file extract command
	fancy-ctrl-z      # fancy-ctrl-z - use with Ctrl-Z to return to normal mode instead of needing fg
	fzf               # fzf and vi-mode both use Ctrl-R so use fzf instead put later
	gcloud            # gcloud - google cloud completions
	gh                # gh - add command completions for gh
	git               # git -  ga git add, gca git commit -av, gd - git diff, gfa - git fetch --all --prune
	git-commit        # git-commit - alias for git commit like git build docs, style, wip
	git-escape-magic  # git-escape-magic - do not need to single quote complex expressions like [<>]
	git-lfs           # git-lfs - completions and alias like glfsi git lfs install glfsls
	gitignore         # gitignore - gi list shows all the .gitignore templates
	globalias         # globalias - touch {1..10}<space>
	gnu-utils         # gnu-utils - use gnu without the g prefix
	golang            # golang - alias like gob for go build
	helm
	history   # history - h for history and hs for history | grep but CTRL-R from fzf is
	iterm2    # iterm2 - iterm2_profile <profile> to change it
	jsontools # pp_json pretty print urlencode_json
	kubectl   # kubectl - completions and k kubectl, kaf kubectl apply -f
	localstack
	macos     # tab opens directory in new tab, ofd open in finder
	man       # insert man before previous command
	marked2   # markdown preview
	microk8s  # microk8s adds aliases like ce for enable or mh for helm, mst for m start
	multipass # multipass - adds mp for multipass and mps for multipass shell
	npm
	nvm
	opentofu   # open source terraform
	pip        # pip - command completion
	podman     # pbl: podman build
	poetry     # aliases
	poetry-env # each entry and poetry shell starts
	pre-commit # prc: pre-commit, prcr pre-commit run
	python     # python py for python, pyfind for find *.py pygrep rand-quote ripgrep
	rg         # rg - completions
	rsync      # rsync - adda rsync-copy for -avz
	rust       # completions
	ssh        # host completion from ..ssh/config
	# sudo       # ESC twice to add sudo to previous command (too annoying)
	tailscale # completions
	terraform # terraform - tfa for apply, tfv for validate...
	themes
	thefuck    # ESC twice to correct command (conflicts with sudo plugin do not use together)
	tmux       #  ts for tmus attach -t, tl: tmux list-sessions
	tmuxinator # txs tmuxinator start
	transfer
	vscode               # vsc: code, vscg
	wd                   # wd - warp directory do a wd add to add to a list of directories
	web-search           # google - runs google from command line, bing, ddg
	wp-cli               # Wordpress command line
	xcode                # xcb: xcodebuild
	z                    # yet another directory nav, z p: finds the directory that has p the most
	zsh-interactive-cd   # cd<TAB> starts fzf
	zsh-navigation-tools # n-history, n-cd, n-kill

)

log_verbose "adding zinit plugins must be done early in installation"
# https://gist.github.com/laggardkernel/4a4c4986ccdcaf47b91e8227f9868ded
# powerlevel10k - status bar
# zsh-autosuggestions - long suggestions
# test if compaudit returns any bad permissions and if it does seal it up.
# https://stackoverflow.com/questions/12137431/test-if-a-command-outputs-an-empty-string
# note that compaudit does not always exist so check for it and then its output

if ! config_mark "$(config_profile_interactive_zsh)"; then
	config_add "$(config_profile_interactive_zsh)" <<-EOF
		command -v compaudit >/dev/null && [[ \$(compaudit) ]] && compaudit | xargs chmod g-w,o-w
		# plugins must be before the source on-my-zsh
		plugins+=(
			${PLUGIN[*]}
		)
		# oh-my-zsh will utter it is in asdf so suppress the warning
		source \$ZSH/oh-my-zsh.sh &> /dev/null
		source "\$(brew --prefix)/opt/zinit/zinit.zsh"
		# https://github.com/zdharma-continuum/zinit
		zinit depth"1" wait for \
			zsh-users/zsh-autosuggestions \
			zsh-users/zsh-syntax-highlighting \
			oldratlee/hacker-quotes \
			richtong/bash-my-gcp
		# cannot wait still have to call
		zinit light romkatv/powerlevel10k
		zinit light joel-porquet/zsh-dircolors-solarized
		setupsolarized
	EOF
fi

# instead of replace, just append
# use -x so we don't replace if it is already there
# also run after the config_add above to get the mark
#log_warning "if plugins is already in .zshrc remove manually and rerun"
#config_replace -x "$(config_profile_interactive_zsh)" plugins "plugins=(${PLUGIN[*]})"

# https://github.com/zdharma-continuum/zinit/issues/418
if [[ ! -r $(brew --prefix)/opt/zinit/doc/zinit.1 ]]; then
	log_verbose "Patch for brew formula problem with zinit #418"
	ln -s "$(man --path zinit)" "$(brew --prefix)/opt/zinit/doc/zinit.1"
fi
