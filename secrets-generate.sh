#!/usr/bin/env bash
##
## Create all the files need for a new developers ssh keys
## for github and other sites. These are custom for each provider
## This wraps the keys in the new bcrypt format using openssh version 6.5 
set -u && SCRIPTNAME="$(basename "$0")"
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
ORG="${ORG:-netdron.es}"
if [[ ! -v USERS ]]; then USERS=("$USER@$ORG"); fi
declare -a SITES
SITES=(github.com amazon.com cloud.google.com)
# order is important uses the last key to fill out for all the sites not # mentioned
# cannot do default substituion with arrays
if [[ ! -v TYPES ]]; then TYPES=(ed25519 rsa ed25519); fi
# For each secret, what is url for adding the .pub file
#/users/$USER?section=security_credentials"
if [[ ! -v URLS ]]; then
	URLS=("https://github.com/settings/keys"
		  "https://console.aws.amazon.com/iam/home?region=us-west-2"
		  "https://cloud.google.com")
fi
if [[ ! -v DATES  ]]; then DATES=("$(date +%Y-%m)"); fi
SECRETS_DIR="${SECRETS_DIR:-"$HOME/.ssh"}"
CONFIG="${CONFIG:-false}"
FORCE="${FORCE:-false}"
FLAGS="${FLAGS:-""}"
while getopts "hdvfms:u:y:t:l:" opt; do
	case "$opt" in
	h)
		cat <<-EOF

			Generate the standard keys needed for an organization

			Usage: $SCRIPTNAME [flags] [target web sites for keys...]
			flags:  -d debug, -v verbose, -h help
			        -f force the overwrite of existing keys (default: $FORCE)
			        -m modify the config files to use the new secrets (default: $CONFIG)
			        -s the directory for the secrets (default: $SECRETS_DIR)
			        -u space separate list of user names, uses the last name over as needed  default:
			           ${USERS[*]}
			        -y date stamp for keys use the last element as needed default:
					   ${DATES[*]}
			        -t type of key list uses the last element as needed for all sites default:
			           ${TYPES[*]}
			        -l list of urls that match the secrets, use the last one as needed
		EOF
		printf "\t%s\n" "${URLS[*]}"
		cat <<-EOF

			positionals: specific keys to generate for these sites
			        ${SITES[*]}

		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		FLAGS+=" -v "
		;;
	f)
		FORCE=true
		FLAGS+=" -f "
		;;
	m)
		CONFIG=true
		;;
	s)
		SECRETS_DIR="$OPTARG"
		;;
	u)
		mapfile -t USERS <<<"$OPTARG"
		;;
	y)
		mapfile -t DATES <<<"$OPTARG"
		;;
	t)
		mapfile -t TYPES <<<"$OPTARG"
		;;
	l)
		mapfile -t URLS <<<"$OPTARG"
		;;
	*)
		echo "no -$opt"
		;;
	esac
done

# shellcheck disable=SC1090
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

shift $((OPTIND - 1))

if (($# > 0)); then
	# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
	mapfile -t SITES <<<"$@"
fi

for i in $(seq 0 $((${#SITES[@]} - 1))); do

	user="${USERS[i]:-$user}"
	site="${SITES[i]:-$site}"
	date="${DATES[i]:-$date}"
	type="${TYPES[i]:-$type}"
	url="${URLS[i]:-$url}"
	log_verbose "item $i for $user $site $date $type for $url"

	# cannot use the stdout to return the key created because need this for
	# passphrase input
	key="$user-$site-$date.id_$type"
	log_verbose "generating $key"
	# shellcheck disable=SC2086
	"$SCRIPT_DIR/secrets-keygen.sh" $FLAGS -u "$user" -t "$site" -y "$date" \
		-k "$type" -s "$SECRETS_DIR" -i "$key"

	log_verbose "instruction to upload $key.pub into $url"
	log_message "Browse to $url and copy and paste the file"
	log_verbose logging "$SECRETS_DIR/$key.pub"
	log_file "$SECRETS_DIR/$key.pub"

	log_verbose_file "$SECRETS_DIR/$key" "$SECRETS_DIR/$key.fingerprint"

done
