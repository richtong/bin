#!/usr/bin/env bash
##
## Install Git Tools
## https://news.ycombinator.com/item?id=9091691 for linux gui
## https://news.ycombinator.com/item?id=8441388 for cli
## https://www.npmjs.com/package/onepass-cli for npm package
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
GIT_USERNAME="${GIT_USERNAME:-"${USER^}"}"
GIT_PRIVATE_EMAIL="${GIT_PRIVATE_EMAIL:-"1782087+richtong@users.noreply.github.com"}"
GIT_EMAIL="${GIT_EMAIL:-"$USER@tongfamily.com"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvu:e:p:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Github Tools
			    usage: $SCRIPTNAME [ flags ]
			    flags: -d debug, -v verbose, -h help
				       -u pretty git user name for git log (default $GIT_USERNAME )
				       -e git email extension (default $GIT_EMAIL)
					   -p git private email (default $GIT_PRIVATE_EMAIL)
			we use the private email by default
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
	u)
		GIT_USERNAME="$OPTARG"
		;;
	e)
		GIT_EMAIL="$OPTARG"
		;;
	p)
		GIT_PRIVATE_EMAIL="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh \
	lib-version-compare.sh lib-config.sh

# Put title case on the user name
if [[ -z $(git config --global user.name) ]]; then
	# https://jeffbailey.us/blog/2020/01/20/push-declined-due-to-email-privacy-restrictions-on-github/
	log_verbose "no user name set changing to $GIT_USERNAME"
	# the caret converts to title case
	# https://stackoverflow.com/questions/11392189/converting-string-from-uppercase-to-lowercase-in-bash
	git config --global user.name "${GIT_USERNAME^}"
fi

if [[ -z $(git config --global user.email) ]]; then
	log_verbose "no email set changing to $GIT_PRIVATE_EMAIL"
	git config --global user.email "${GIT_PRIVATE_EMAIL,,}"
fi

if [[ -z $(git config --global checkout.defaultRemote) ]]; then
	log_verbose "no checkout.defaultRemote changing to origin"
	git config --global checkout.defaultRemote origin
fi

if [[ -z $(git config --global pull.ff) ]]; then
	log_verbose "no pull.ff set turn fast forward only"
	git config --global pull.ff only
fi

# https://stackoverflow.com/questions/10418975/how-to-change-line-ending-settings
if [[ -z $(git config --global core.autocrlf input) ]]; then
	autocrlf=input
	if in_os windows; then
		autocrlf=true
	fi
	git config --global core.autocrlf "$autocrlf"
fi

# Git is changing its default and this gets rid of warning messages
# There is no simple in git 1.7
if vergte "$(git version | cut -f3 -d' ')" 1.8; then
	if ! git config --global push.default | grep ^simple; then
		git config --global push.default simple
	fi
fi

if [[ ! $(git config --global ff.only) =~ only ]]; then
	git config --global ff.only only
fi

log_verbose "in the newest version of git specify fast forward only so you do not get accidental merges"
git config pull.ff only
# https://git-scm.com/docs/git-config show summary of submodules
# the number of commits to show -1 means all of them
git config --global status.submodulesummary 2
# use lfs for now, s3 for very large files

if ! in_os mac; then
	log_exit "Linux installed"
fi

# need for convenience with git and used in workflows so get used to it
# https://github.com/github/hub
# https://github.blog/2021-03-04-4-things-you-didnt-know-you-could-do-with-github-actions/
# Git hub
# act : run github actions locally
# gh : official github cli
#	hub : deprecated and break git completions
log_verbose "do not installed hub the completions interfer with git and it is deprecated"
PACKAGES+=(
	gh
	act
)

# meld is ugly compared with the default
# https://stackoverflow.com/questions/43317697/setting-up-and-using-meld-as-your-git-difftool-and-mergetool-on-a-mac
# PACKAGES+=" meld "

# shellcheck disable=SC2086
cask_install "${PACKAGES[@]}"

gh config set git_protocol ssh
# https://dev.to/softprops/digitally-unmastered-the-github-cli-edition-1cc4
# make it easy to set default-branch disable check as gh will interpret later
# shellcheck disable=SC2016
# this does not appear to work anymore
gh alias set default-branch \
	'api -X PATCH repos:/:owner/:repo --raw-field default_branch=$1'

# gh completion now handled by homebrew
# https://cli.github.com/manual/gh_completion
# eval "$(gh completion -s bash)"
# for old gh completion has bug where cannot source direction so create a file
#gh completion --shell bash >"$SCRIPT_DIR/gh-completion-bash.sh"
#if ! config_mark; then
#config_add <<-EOF
#source $$(gh completion --shell bash)
#Note this generates an error with an incorrect line at the end
#source "$SCRIPT_DIR/gh-completion-bash.sh"
#EOF
#fi

# do not like meld that much
# https://stackoverflow.com/questions/43317697/setting-up-and-using-meld-as-your-git-difftool-and-mergetool-on-a-mac
# git config --global merge.tool meld
# git config --global diff.guitool meld
# log_verbose "to use a graphical tool use for merges use git mergetool and for"
# log_verbose "diffs then use git difftool"
# https://medium.com/usevim/git-and-vimdiff-a762d72ced86

# https://github.blog/2020-07-27-highlights-from-git-2-28/#introducing-init-defaultbranch
log_verbose "install vimdiff can edit all files with vi \$(git diff --name-only)"
git config --global diff.tool vimdiff
git config --global merge.tool vimdiff
# no prompting for next file
git config --global difftool.prompt false
log_verbose "main is now the default branch for all new repos"
git config --global init.defaultBranch main
