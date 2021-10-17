#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
##
## Bump from one version of Python to the next like 3.9 to 3.10
## Handles cases where asdf and direnv are installed
## bumps Homebrew
##
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
# need to use trap and not -e so bashdb works
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
NEW_PYTHON="${NEW_PYTHON:-3.10}"
OLD_PYTHON="${OLD_PYTHON:-3.9}"

# asdf needs the full version like 3.9.7
NEW_PYTHON_MINOR="${NEW_PYTHON_MINOR:-$NEW_PYTHON.0}"
OLD_PYTHON_MINOR="${OLD_PYTHON_MINOR:-$OLD_PYTHON.7}"

OPTIND=1
# which user is the source of secrets
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Upgrades from

			usage: $SCRIPTNAME [flags...] new old
			  new version to 3 digits (default: $NEW_PYTHON_MINOR)
			  old (default: $OLD_PYTHON_MINOR)

			  -h help
			  -v verbose
			  -d single step debugging (not work use shelldb)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-config.sh lib-install.sh
shift $((OPTIND - 1))

log_verbose "OPTIND is $OPTIND and $# arguments left"
if (($# > 0)); then
	NEW_PYTHON_MINOR="$1"
	NEW_PYTHON="${NEW_PYTHON_MINOR%.*}"
	shift
fi

if (($# > 0)); then
	OLD_PYTHON_MINOR="$1"
	OLD_PYTHON="${OLD_PYTHON_MINOR%.*}"
	shift
fi

if ! in_os mac; then
	log_exit "Mac only"
fi

for version in "$OLD_PYTHON" "$NEW_PYTHON"; do
	log_verbose "Install Old python $version"
	package_install "python@$version"
done

log_verbose "brew unlink $OLD_PYTHON and link $NEW_PYTHON"
brew unlink "python@$OLD_PYTHON"
brew link "python@$NEW_PYTHON"

if command -v asdf; then
	log_verbose "asdf detect install $NEW_PYTHON_MINOR"
	asdf install python "$NEW_PYTHON_MINOR"
	asdf global python "$NEW_PYTHON_MINOR"
fi

if command -v direnv; then
	log_verbose "direnv detected touch .envrc to set new version"
	touch "$HOME/.envrc"
fi
