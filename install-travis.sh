#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Install the travis command line tools
##
## There is a related install-travis-env.sh that upgrades a Ubuntu 12.04
## images into something that we can use but it isn't needed for development
## machines and is just for testing Travis CI with our M2 stuff
##
## See https://github.com/travis-ci/travis.rb#note-on-ubuntu
##
## @author Rich Tong
## @returns 0 on success
#

set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
while getopts "hdv" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Install Travis Command line interface
			flags: -h help
				   -d $(! $DEBUGGING || echo "no ")debugging
				   -v $(! $VERBOSE || echo "not ")verbose
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
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-version-compare.sh

set -u

if command -v travis && vergte "$(travis version)" 1.8.0; then
	exit 0
fi

# Here we go
bash "$SCRIPT_DIR/install-ruby.sh"

if verlt "$(ruby -v | cut -d' ' -f 2)" 1.9.3; then
	echo "$SCRIPTNAME: Need ruby at least 1.93, got $(ruby -v)"
	exit 1
fi

# Do not need to lock to version 1.8 anymore
#sudo gem install travis -v 1.8.0 --no-rdoc --no-ri
sudo gem install travis --no-rdoc --no-ri

if verlt "$(travis version)" 1.8; then
	log_exit 2 "$SCRIPTNAME: Need travis 1.8 or greater, got $(travis version)"
fi

log_verbose login so you can access private repos
if ! travis accounts; then
	log_verbose now login with github and your password and two factor authentication if enabled
	travis login --pro
fi
