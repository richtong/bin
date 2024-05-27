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
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
GIT_USERNAME="${GIT_USERNAME:-"${USER^}"}"
GIT_EMAIL="${GIT_EMAIL:-"1782087+richtong@users.noreply.github.com"}"
# no longer use a public email
# GIT_EMAIL="${GIT_EMAIL:-"$USER@tongfamily.com"}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvu:e:f" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Github Tools
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
				   -u pretty git user name for git log (default $GIT_USERNAME )
				   -e git email (default $GIT_EMAIL)
				   -f blow away the .git defaults with these (default: $FORCE)
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
	u)
		GIT_USERNAME="$OPTARG"
		;;
	e)
		GIT_EMAIL="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh \
	lib-version-compare.sh lib-config.sh

# the caret converts to title case
# https://stackoverflow.com/questions/11392189/converting-string-from-uppercase-to-lowercase-in-bash
# needs special handling for windows
# https://stackoverflow.com/questions/10418975/how-to-change-line-ending-settings
# https://stackoverflow.com/questions/11514075/what-is-the-difference-between-an-annotated-and-unannotated-tag
# https://stackoverflow.com/questions/5195859/how-do-you-push-a-tag-to-a-remote-repository-using-git
declare -A VAR+=(
	[push.followTags]="true"
	[user.email]="${GIT_EMAIL,,}"
	[user.name]="${GIT_USERNAME^}"
	[core.autocrlf]="$(in_os windows && echo true || echo input)"
	[init.defaultBranch]="main"
	[push.followTags]="true"
	[commit.verbose]="true"
	[ff.only]="only"
	[rebase.autoStash]="true"
	[checkout.defaultRemote]="origin"
)
# Git is changing its default and this gets rid of warning messages
# There is no simple in git 1.7
if vergte "$(git version | cut -f3 -d' ')" 1.8; then
	log_verbose "git > 1.8 do simple push default"
	VAR+=(
		[push.default]="simple"
	)
fi

for FLAG in "${!VAR[@]}"; do
	log_verbose "checking if $FORCE or gitconfig --global $FLAG exists if not"
	if $FORCE || ! git config --global "$FLAG" >/dev/null; then
		log_verbose "git config --global $FLAG ${VAR[$FLAG]}"
		git config --global "$FLAG" "${VAR[$FLAG]}"
	fi
done
exit

log_verbose "in the newest version of git specify fast forward only so you do not get accidental merges"
if [[ ! $(git config --global pull.ff) =~ only ]]; then
	git config pull.ff only
fi

# https://stackoverflow.com/questions/74486167/git-clone-recurse-submodules-throws-error-on-macos-transmission-type-file-n
# git submodules now failing with transmission type 'file' not allowed
# https://git-scm.com/book/en/v2/Git-Internals-Transfer-Protocols
# https://git-scm.com/book/en/v2/Git-Internals-Git-Objects
# https://bugs.launchpad.net/ubuntu/+source/git/+bug/1993586
# https://github.blog/2022-10-18-git-security-vulnerabilities-announcead/#cve-2022-39253
# this closes a security hole where a symlink in .git/objects causes a clone to
# copy that data
log_verbose "Allowing --recurse-submodules so make sure that all modules are trusted"
if [[ ! $(git config --global protocol.file.allow) =~ always ]]; then
	git config --global protocol.file.allow always
fi

# https://git-scm.com/docs/git-config show summary of submodules
# the number of commits to show -1 means all of them
# this is very slow so remove for now particularly for WSL to Windows
#git config --global status.submodulesummary 2
# use lfs for now, s3 for very large files

# need for convenience with git and used in workflows so get used to it
# https://github.com/github/hub
# https://github.blog/2021-03-04-4-things-you-didnt-know-you-could-do-with-github-actions/
# Git hub
# act : run github actions locally
# gh : official github cli
# hub : deprecated and breaks git completions so do not use
# nbdime: jupyter notebook diff and merge with git integration to git diff
# https://scottbanwart.com/blog/2021/03/weekly-journal-10-asdf-pre-commit-gitlint/
# gitlint - linting git commits
# should use https://www.conventionalcommits.org/ format
# feat(install-1password)!: add feature or breaking change vs. fix:
log_verbose "do not installed hub the completions inferior with git and it is deprecated"
PACKAGE+=(

	act
	gh
	gitlint
	nbdime
	pre-commit

)

# we use the pip install version becasue brew install mkdocs has no easy way
# to add themes
# material design layout for mkdocs
# mkdocs: static site generator to create readmes that go to github pages
# mkdocs-material: Material Design theme to create
# pymdown-extensions: utilities
# fontawesome-markdown: font-awesome symbols for markdown
# https://medium.com/swlh/publish-a-static-website-in-a-day-with-mkdocs-and-netlify-3cc076d0efaf
PIP_PACKAGE+=(
	mkdocs
	mkdocs-material
	pymdown-extensions
	fontawesome-markdown
)

# meld is ugly compared with the default
# https://stackoverflow.com/questions/43317697/setting-up-and-using-meld-as-your-git-difftool-and-mergetool-on-a-mac
# PACKAGE+=" meld "

# shellcheck disable=SC2086
package_install "${PACKAGE[@]}"

# nbdime pyyaml virtualenv no long key only on ubuntu anyway
if ! in_os mac; then
	log_verbose "brew link virtualenv, pyyaml as they are keg-only"
	# virtualenv used by pre-commit
	brew link nbdime pyyaml virtualenv
fi

pip_install "${PIP_PACKAGE[@]}"

log_verbose "check if authenticated"
if ! gh auth status | grep -q "Logged in"; then
	# need the workflow scope to allow edits of github actions
	gh auth login -s workflow
	gh config set git_protocol ssh
fi

# https://dev.to/softprops/digitally-unmastered-the-github-cli-edition-1cc4
# make it easy to set default-branch disable check as gh will interpret later
# shellcheck disable=SC2016
# deprecated
#gh alias set default-branch \
#	'api -X PATCH repos:/:owner/:repo --raw-field default_branch=$1'
#	deprecated
#gh default-branch main
# https://stackoverflow.com/questions/74960450/change-default-branch-via-cli
gh repo edit --default-branch main

# https://github.com/topics/gh-extension
# gh-dash - dashboard
# gh-poi - safely delete local branches
# gh-markdown-preview - markdown preview of README.md
# gh-f - fuzzy finder inside repos
# gh-cp - copy files from remote repo without cloning
GH_EXTENSION+=(
	dlvhdr/gh-dash
	seachicken/gh-poi
	yusukebe/gh-markdown-preview
	gennaro-tedesco/gh-f
	mislav/gh-cp
)

for extension in "${GH_EXTENSION[@]}"; do
	log_verbose "Install gh extension $extension"
	gh extension install "$extension"
done
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
log_verbose "install vimdiff can edit all files with vi $(git diff --name-only)"
git config --global diff.tool vimdiff
git config --global merge.tool vimdiff
# no prompting for next file
git config --global difftool.prompt false

log_verbose "main is now the default branch for all new repos"
git config --global init.defaultBranch main

# https://nbdime.readthedocs.io/en/latest/
# https://nbdime.readthedocs.io/en/latest/vcs.html
nbdime config-git --enable --system
