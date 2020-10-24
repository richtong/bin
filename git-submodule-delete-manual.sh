#!/usr/bin/env bash
##
## Delete a submodule
## Amazingly there is no automatic way to do this
##
##@author Rich Tong
##@returns 0 on success
#
# https://coderwall.com/p/csriig/remove-a-git-submodule
# https://git.wiki.kernel.org/index.php/GitSubmoduleTutorial
# https://www.freecodecamp.org/forum/t/how-to-remove-a-submodule-in-git/13228
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
REPOS="${REPOS:-""}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Delete a submodule
			    usage: $SCRIPTNAME [ flags ] [ submodules_path ]
			    flags: -d debug, -v verbose, -h help
			           -f force the change otherwise the default is a dry run
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
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
REPOS="${REPOS:-"$@"}"

log_verbose "deleting $REPOS"

if ! in_os mac; then
	log_warning only tested on the Mac
fi

log_verbose "convert the repos in paths relative to $SOURCE_DIR"
relatives=""
# https://stackoverflow.com/questions/2564634/convert-absolute-path-into-relative-path-given-a-current-directory-using-bash
for repo in $REPOS; do
	relatives+=" $(realpath --relative-to="$SOURCE_DIR" "$repo") "
done
log_verbose "$relatives are the new paths"
REPOS="$relatives"

log_verbose delete the relevant submodule lines in .gitmodules
# https://unix.stackexchange.com/questions/56 123/remove-line-containing-certain-string-and-the-following-line
# be careful believe GITMODULE is a reserved name from git
GITMOD="$SOURCE_DIR/.gitmodules"
GITMOD_TMP="$GITMOD.$$"
GITCONF="$SOURCE_DIR/.git/config"
GITCONF_TMP="$GITCONF.$$"
log_verbose "creating a temporary $GITMOD_TMP and $GITCONF_TMP"
cp "$GITMOD" "$GITMOD_TMP"
cp "$GITCONF" "$GITCONF_TMP"
for repo in $REPOS; do
	if [[ ! -e $repo ]]; then
		log_warning "$repo does not exist skipping"
		continue
	fi
	log_verbose "removing $repo from .gitmodules"
	sed -in "/$repo/d" "$GITMOD_TMP"
	log_verbose "removing $repo from .git/config plus 2 lines"
	sed -in "/$repo/,+2d" "$GITCONF_TMP"
done
log_warning will rewrite .gitmodules .git/config
if $VERBOSE; then
	cat "$GITMODULE_TMP"
	cat "$GITCONF_TMP"
fi

log_verbose back .gitmodules with a date stamp
# https://stackoverflow.com/questions/8228047/adding-timestamp-to-a-filename-with-mv-in-bash
cp "$GITCONF" "$GITCONF.$(date +"%Y%M%D%H%M%S")"
cp "$GITMOD" "$GITMOD.$(date +"%Y%M%D%H%M%S")"
if ! $FORCE; then
	log_warning "would change $GITMOD and $GITCONF"
else
	mv "$GITMOD_TMP" "$GITMOD"
	mv "$GITCONF_TMP" "$GITCONF"
	log_verbose must now commit these changes
	git add "$SOURCE_DIR/.gitmodules"
	git commit -m "removed $REPOS from .gitmodules"
fi

log_verbose now get rid of git cache
for repo in $REPOS; do
	log_verbose "remove cached $SOURCE_DIR/$repo"
	if $FORCE; then
		git rm --cached "$SOURCE_DIR/$repo"
	fi
done

log_verbose remove the .git/modules directories

for repo in $REPOS; do
	log_verbose "remove .git/modules/$repo"
	if $FORCE; then
		rm -rf ".git/modules/$repo"
	fi
done

log_verbose commit it all
if $FORCE; then
	git commit -m "Removed $REPOS"
fi

log_verbose now remove the repos
for repo in $REPOS; do
	log_verbose "removing $SOURCE_DIR/$repo"
	if $FORCE; then
		# prevents delete if $SOURCE_DIR is not set
		# https://github.com/koalaman/shellcheck/wiki/SC2115
		rm -rf "${SOURCE_DIR:?}/$repo"
	fi
done
