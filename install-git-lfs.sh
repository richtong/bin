#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install git lfs from package cloud
## Note we are trusting them as we are doing a sudo bash!
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"

REMOVE="${REMOVE:-false}"

OPTIND=1
VERSION=${VERSION:-"1.2.0"}
while getopts "hdvi:r" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			    $SCRIPTNAME: Install git lfs
					flags:
					   -d $($DEBUGGING && echo "no ")debugging
					   -v $($VERBOSE && echo "not ")verbose
				     -i git lfs release (default $VERSION)
					   -r $(! $REMOVE && echo "install" || echo "remove") git lfs from current repo
		EOF
		exit 0
		;;
	d)
		# invert the variable when flag is set
		DEBUGGING="$($DEBUGGING && echo false || echo true)"
		export DEBUGGING
		;&
	v)
		VERBOSE="$($VERBOSE && echo false || echo true)"
		export VERBOSE
		# add the -v which works for many commands
		if $VERBOSE; then export FLAGS+=" -v "; fi
		;;
	r)
		REMOVE="$($REMOVE && echo false || echo true)"
		;;
	i)
		VERSION="$OPTARG"
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$HOME/Downloads/git-lfs-$VERSION"}
DOWNLOAD_URL=${DOWNLOAD_URL:-"https://github.com/github/git-lfs/releases/download/v$VERSION/git-lfs-darwin-amd64-$VERSION.tar.gz"}
source_lib lib-install.sh lib-mac.sh lib-util.sh

if ! $REMOVE; then
	log_verbose "try to install git lfs"
	package_install git-lfs
	if ! command -v git-lfs &>/dev/null; then
		if in_os mac; then
			log_verbose "package install failed try to download"
			if [[ ! -e $DOWNLOAD_DIR ]]; then
				download_url_open "$DOWNLOAD_URL"
			fi
			# Note that the git install must be run out of the working directory
			if ! cd "$DOWNLOAD_DIR"; then
				log_error 1 "no $DOWNLOAD_DIR"
			fi
			sudo "./install.sh"
			cd - || false
		elif in_os linux; then
			log_verbose "try to install debian from source"
			curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
		fi
	fi
	if command -v git-lfs &>/dev/null; then
		log_verbose "git lfs install running"
		git lfs install
	fi
else
	log_verbose "remove git lfs from current repo"
	# https://www.ryangittings.co.uk/blog/removing-git-lfs-netlify/
	if ! git rev-parse --is-inside-work-tree >/dev/null; then
		log_exit 1 "Not a git repo"
	fi
	log_verbose "download all the git lfs files"
	git lfs fetch --all
	log_verbose "checkout all"
	git lfs checkout
	log_verbose "uninstall git lfs"
	git lfs uninstall

	if [[ -r .gitattributes ]]; then
		log_verbose "found .gitattributes"
		# https://kodekloud.com/blog/read-file-in-bash/
		while read -r LINE; do
			log_verbose "Got $LINE"
			log_verbose "untrack ${LINE%% *}"
			git lfs untrack "${LINE%% *}"
		done <.gitattributes
	fi

	log_verbose "add renormalized files"
	git add --renormalize .
	log_verbose "check this is correct and push"
fi
