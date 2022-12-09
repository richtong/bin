#!/usr/bin/env bash
##
## Add the specific groups (deprecated)
##
##@author Rich Tong
##@returns 0 on success
#
set -ue && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
USER_FILE=${USER_FILE:-"$(readlink -f "$SCRIPT_DIR/../etc/users.txt")"}
GROUP_FILE=${GROUP_FILE:-"$(readlink -f "$SCRIPT_DIR/../etc/groups.txt")"}
SET_PASSWORD=${SET_PASSWORD:-false}
KEY_REPO=${KEY_REPO:-"public-keys"}
ORG_NAME="${ORG_NAME:-tongfamily}"
ORG_DOMAIN="${ORG_DOMAIN:-$ORG_NAME.com}"
# The default is an encrypted version of the usual password
# shellcheck disable=SC2016
PASSWORD=${PASSWORD:-'$6$8LMtrP9m5nsLVzxi$sVod2Xc3kdFU9BA0wkntnlsBbz8bGwS32YIrTrLC1huzcKXBBQXbBiUekKLGMYDlwEU0xmty2QiHYdz4MnO0a/'}
while getopts "hdvg:u:k:fx:" opt; do
	case "$opt" in
	h)
		echo "$SCRIPTNAME: reads user and uid from standard input"
		echo flags: -d debug, -h help -v verbose
		echo "      -u user and uid file (default: $USER_FILE)"
		echo "      -g list of new groups in a text file (default: $GROUP_FILE)"
		echo "      -k ssh key directory ws dir (default: $KEY_REPO)"
		echo "      -f force the password reset (default: $SET_PASSWORD)"
		echo "      -x default password (the default is the normal one"
		echo "         to create a new default use make-password.sh"
		exit 0
		;;
	d)
		# -x is x-ray or detailed trace, -v is verbose, trap DEBUG single steps
		echo "$SCRIPTNAME: Warning this script can not be single stepped"
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	u)
		USER_FILE="$OPTARG"
		;;
	g)
		GROUP_FILE="$OPTARG"
		;;
	k)
		KEY_REPO="$OPTARG"
		;;
	f)
		SET_PASSWORD=true
		;;
	x)
		PASSWORD="$OPTARG"
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done

# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh

GIT_REPOS=${GIT_REPOS:-"$WS_DIR/git"}

log_verbose check to see if iam-key running
if sudo service iam-key status | grep -q running; then
	log_exit assume iam-key has everyone and we only need
fi

log_warning no iam-key found using the older installation method
log_warning make sure to review infra/etc and make sure the
log_warning user and group files are correct!!!!

# Add docker group if not already there
if ! command -v docker >/dev/null; then
	"$BIN_DIR/install-docker.sh"
fi

REPO_PATH="$(git_install_or_update "$KEY_REPO")"

pushd "$REPO_PATH"

"$SCRIPT_DIR/add-groups.sh"

if $DEBUGGING; then
	NEW_UID=8003
	NEW_GROUP=$ORG_NAME
	NEW_USER=deploy
	EXTRA_GROUPS=ops,sudo,docker
	"$SCRIPT_DIR/add-user.sh" -i "$NEW_UID" -s "$NEW_USER" -g "$NEW_GROUP" -t user -e "$EXTRA_GROUPS"
fi

# debug code for user and agent insertions
if "$DEBUGGING"; then
	# 5006 tongfamily user noah sudo,docker x x
	NEW_UID=5006
	NEW_GROUP=$ORG_NAME
	USER_TYPE=user
	NEW_USER=noah
	EXTRA_GROUPS=dev,sudo,docker
	GITHUB_NAME=x
	EMAIL=noah@ORG_DOMAIN
	echo Testing $USER_TYPE $NEW_UID
	"$SCRIPT_DIR/add-user.sh" -i "$NEW_UID" -g "$NEW_GROUP" -t user -s "$NEW_USER" -e "$EXTRA_GROUPS" -n "$GITHUB_NAME" -m "$EMAIL"
fi
if "$DEBUGGING"; then
	NEW_UID=8001
	NEW_GROUP=$ORG_NAME
	USER_TYPE=agent
	NEW_USER=build
	EXTRA_GROUPS=ops,sudo,docker
	GITHUB_NAME=$ORG_NAME-build
	EMAIL=build@$ORG_DOMAIN
	echo Testing $USER_TYPE $NEW_UID
	"$SCRIPT_DIR/add-user.sh" -i "$NEW_UID" -g "$NEW_GROUP" -t user -s "$NEW_USER" -e "$EXTRA_GROUPS" -n "$GITHUB_NAME" -m "$EMAIL"
fi

# Now loop through all users turn off debug because the trap is not compatible
# with the read loop but we no longer need this because we use fd 10 for the file input
# trace_off
# looks wierd, but we pipe in the file at the bottom
# http://linuxpoison.blogspot.com/2012/08/bash-script-how-read-file-line-by-line.html
while read -u 10 -r NEW_UID NEW_USER NEW_GROUP USER_TYPE EXTRA_GROUPS GITHUB_NAME EMAIL; do
	if [[ -z $NEW_UID || $NEW_UID =~ "^#" ]]; then
		log_verbose skipping blank or comment
		continue
	elif $VERBOSE; then
		echo read "$NEW_UID" "$NEW_USER" "$NEW_GROUP" "$USER_TYPE" \
			"$EXTRA_GROUPS" "$GITHUB_NAME" "$EMAIL"
	fi
	"$SCRIPT_DIR/add-user.sh" -i "$NEW_UID" -s "$NEW_USER" -g "$NEW_GROUP" \
		-t "$USER_TYPE" -e "$EXTRA_GROUPS" \
		-n "$GITHUB_NAME" -m "$EMAIL"
	# the syntax below means send $USER_FILE to fd 10
done 10<"$USER_FILE"

#trace_on
