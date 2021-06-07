#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Runs the build from crontab passing parameters to wscons
## What it does depends on the $USER variable
##
## @author Rich Tong
## @returns 0 on success

# Note -o pipefail causes ssh to close the connection
# if any of the pipelines have an error in them, so for
# scripts that are going to be remote, turn them off
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
# Crontab jobs do not source anything, so we need to do it manually
FORCED=${FORCED:-false}
# USER is not defined in chron so set to the Logon name
USER=${USER:-"$LOGNAME"}
ORG_DOMAIN="${ORG_DOMAIN:-tongfamily.com}"
GIT_KEY=${GIT_KEY:-"$USER@tongfamily.com-github.com.id_ed25519"}
TESTING=${TESTING:-false}

# only build agent needs to do the full precheck
BUILD_ARGS=${BUILD_ARGS:-""}
if [[ $USER == build ]]; then
	BUILD_ARGS=${BUILD_ARGS:-"pre"}
fi

while getopts "hdvfu:k:t" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME crontab job run regularly or on git commit"
		echo flags: -d debug, -h help, -v verbose
		echo "       -f force a clean build"
		echo "       -t do not use live cameras use test sources"
		echo "       -u agent being installed: (default $USER)"
		echo "          build does a clean build with precheck"
		echo "          deploy incremental build start server"
		echo "          test incremental build then system tests"
		echo "       -k ssh key to use for github access (default $GIT_KEY)"
		echo "positionals are passed to (default: $BUILD_ARGS)"
		exit 0
		;;
	d)
		export DEBUGGING=true
		;&
	v)
		export VERBOSE=true
		;;
	f)
		FORCED=true
		;;
	k)
		GIT_KEY="$OPTARG"
		;;
	u)
		USER="$OPTARG"
		;;
	t)
		TESTING=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-system.sh lib-git.sh lib-keychain.sh

# Get the path changes need this when using ssh and we get no profiles
# shellcheck disable=SC1090,SC1091
if [[ -e "$HOME/.bash_profile" ]]; then source "$HOME/.bash_profile"; fi

shift $((OPTIND - 1))
if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	BUILD_ARGS=("$@")
fi

# http://askubuntu.com/questions/275965/how-to-list-all-variables-names-and-their-current-values
log_verbose "environment is $(
	set -o posix
	set
)"

# the set -u has to come later because SSH_AUTH_SOCK might not be set
set -u

# Make sure we have a docker login
if ! grep -q '"auth":' "$HOME/.docker/config.json"; then
	log_exit 1 "Not logged into docker cannot build"
fi

# Make sure we are using the correct keychain as gnome doesn't handle id_25519 keys
if ! use_openssh_keychain "$GIT_KEY"; then
	log_error 3 "added openssh keychain, reboot required then restart script"
fi

# make sure we have the latest support repos
git_install_or_update -f personal

if ! pushd "$WS_DIR/git/src" >/dev/null; then
	log_error 4 "no $WS_DIR/git/src"
fi

# http://stackoverflow.com/questions/3258243/check-if-pull-needed-in-git
git fetch origin
local_commit=$(git rev-parse @)
# shellcheck disable=SC1083
remote_commit=$(git rev-parse @{u})
if ! $FORCED && [[ "$local_commit" == "$remote_commit" ]]; then
	log_error 5 "No need to build, local same as remote"
fi

log_message Rebuilding
log_message "local repo at $local_commit"
log_message "remote master at $remote_commit"

if pgrep -u "$USER" wscons >/dev/null; then
	log_exit "wscons already running, exiting"
	exit 0
fi

# bring the system running in /var down
kill_system

# Get ready to do a clean build only for the "build" agent
if [[ $USER == build ]]; then
	rm -rf "${WS_DIR:?}/var"
fi

# git pull forces a merge, so do a reset
if [[ $(git symbolic-ref --short HEAD) != master ]]; then
	git checkout master >/dev/null
fi
git reset --hard origin/master
"WS_DIR/git/src/scripts/utility/update-all-submodules.sh"

# use absolute path so can be called via ssh which doesn't get path
if ! "$WS_DIR/git/src/bin/wscons" "${BUILD_ARGS[@]}"; then
	log_warning "build failed trying with less concurrency \(-j 2\)"
	if ! "WS_DIR/git/src/bin/wscons" -j 2 "${BUILD_ARGS[@]}"; then
		log_warning "wscons ${BUILD_ARGS[*]} FAILED building origin $REMOTE"
		# reset so we can try to build again, but continue so the system can
		# restart
		git reset HEAD~1
	fi
fi
echo finished wscons, starting hud-ssdp check

# Preparing to run, setup runtime variables
if [[ ! -e $WS_DIR/var/shared/local/hub-ssdp.config ]]; then
	echo '{ "name": '"$HOSTNAME"' }' >"$WS_DIR/var/shared/local/hub-ssdp.config"
fi

echo starting camera config
add_config() {
	if (($# == 2)); then
		echo '{ "camera0": '"$1"', "camera1": '"$2"' }' > \
			"$WS_DIR/var/shared/local/app-host.config"
	fi
}

echo check for app-host
# set to real cameras for thse servers from src
# Eventually, we will parse the src/data/cameras.txt and look these up
if [[ ! -e $WS_DIR/var/shared/local/app-host.config ]]; then
	echo looking for camera in etc
	# note you have to turn off pipefail because
	# the script fails with an empty grep otherwise
	set +o pipefail
	cameras=$(grep "$HOSTNAME" "$WS_DIR/git/src/infra/etc/camera.txt" |
		head -n 2 | cut -d " " -f 1)
	set -o pipefail
	echo finished camera search
	if (($(echo "$cameras" | wc -w) != 2)); then
		log_verbose "could not find $HOSTNAME in camera.txt"
		case $HOSTNAME in
		odin)
			# bart and tommy
			cameras="10.0.1.{154,244}"
			;;
		thor)
			# pluto and spongebob
			cameras="10.0.1.{227,183}"
			;;
		vlads-zbox)
			# mickey and otto
			cameras="10.0.1.{139,182}"
			;;
		esac
	fi
	add_config $cameras
fi
echo configured cameras
# wipe out the config if in test mode
if "$TESTING"; then
	rm "$WS_DIR/var/shared/local/app-host.config"
fi

echo testing
case $USER in
build)
	log_verbose "$USER only does unit test, does not run"
	;;
deploy)
	log_verbose "$USER start the system"
	echo start run
	run_system
	echo end run
	;;
test)
	log_verbose "$USER start system"
	run_system
	log_verbose "$USER begin overall system tests"
	# LoG_FLAGS set by lib-debug.sh
	# shellcheck disable=SC2086
	"$SCRIPT_DIR/system-test.sh" $LOG_FLAGS
	;;
esac

popd >/dev/null || true
