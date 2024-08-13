#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## install the Amazon AWS components
## Use standard build environment layout
## Expects there to be aws keys in a key file
## And can handle multiple profiles
## https://docs.aws.amazon.com/cli/latest/reference/configure/
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
FLAGS="${FLAGS:-""}"
FORCE=${FORCE:-false}
VERBOSE=${VERBOSE:-false}
AWS_KEY_DIR="${AWS_KEY_DIR:-"$HOME/.ssh/"}"
AWS_KEY_ID_FILE="${AWS_KEY_ID:-"aws-access-key-id"}"
AWS_KEY_FILE="${AWS_KEY:-"aws-access-key"}"
AWS_REGION="${AWS_REGION:-"us-west-2"}"
AWS_OUTPUT_TYPE="${AWS_OUTPUT_TYPE:-"json"}"
AWS_ACCESS_TYPE="${AWS_ACCESS_TYPE:-"sso"}"
AWS_PROFILE="${AWS_PROFILE:-"default"}"
AWS_ORG_NAME="${AWS_ORG_NAME:-"tne"}"
AWS_SSO_ENDPOINT_URL="${AWS_SSO_ENDPOINT_URL:-"https://nedra.awsapps.com/startamazonaws.com"}"
AWS_SSO_REGION="${AWS_SSO_REGION:-"us-east-1"}"

while getopts "hdvi:k:fp:r:o:a:t" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Install the aws configuration parameters
			        usage: $SCRIPTNAME [flags]
			            -d : debug -h : help
			                        -t type of key storage: 1password | sso | veracrypt (default: $AWS_ACCESS_TYPE)
			            -a if SET_AWS_ID and SET_AWS_KEY are not set look in this directory for files (default: $AWS_KEY_DIR)
			            -i the name of the access key identifier (default: $AWS_KEY_ID_FILE.$AWS_PROFILE)
			            -k the name of the access key (default: $AWS_KEY_FILE.$AWS_PROFILE))
			            -f force the installation of credentials and config (default: $FORCE)
			            -p set for a specific profile (default: $AWS_PROFILE)
			            -r aws region for services (default: $AWS_REGION)
			            -o aws output type (default: $AWS_OUTPUT_TYPE)
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
	t)
		AWS_ACCESS_TYPE="$OPTARG"
		export AWS_ACCESS_TYPE
		;;
	a)
		AWS_KEY_DIR="$OPTARG"
		;;
	i)
		AWS_KEY_ID_FILE="$OPTARG"
		;;
	k)
		AWS_KEY_FILE="$OPTARG"
		;;
	p)
		AWS_PROFILE="$OPTARG"
		;;
	r)
		AWS_REGION="$OPTARG"
		;;
	o)
		AWS_OUTPUT_TYPE="$OPTARG"
		;;
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh

if ! command -v aws >/dev/null; then
	"$SCRIPT_DIR/install-aws.sh"
fi

# http://stackoverflow.com/questions/24542934/automating-bat-file-to-configure-aws-s3
mkdir -p "$HOME/.aws"

if ! $FORCE && [[ -e $HOME/.aws && -e $HOME/.aws/credentials || -e $HOME/.aws/config ]]; then
	log_exit "$HOME/.aws/credentials or config already exists will not overwrite"
fi

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
# can now use the aws configure command instead
log_verbose setting region to us-west2 and output to json
aws configure set region "$AWS_REGION" --profile "$AWS_PROFILE"
aws configure set output "$AWS_OUTPUT_TYPE" --profile "$AWS_PROFILE"

# note that you cannot have leading spaces in this file
# since config_mark has the side effect of adding a comment line
# make sure to run this first
# if ! config_mark "$HOME/.aws/config" || $FORCE
# then
#     log_verbose adding config
#     config_add "$HOME/.aws/config" <<-EOF
# [default]
# output = json
# region = us-west-2
# EOF
# fi
#

# https://developer.1password.com/docs/cli/shell-plugins/aws/
if [[ $AWS_ACCESS_TYPE =~ "1password" ]]; then
	log_warning "Open up browser, install and open 1Password browser extension, navigate to aws to see keys"
	if in_os mac; then
		open -a Safari "https://console.aws.amazon.com/iam/home?region=$AWS_REGION#/security_credentials"
		op signin
		op plugin init aws

	elif
		[[ $AWS_ACCESS_TYPE =~ "veracrypt" ]]
	then
		log_warning "Do not backup ~/.aws/credentials into git"
		log_warning "you can use a soft link to a Veracrypt file"
		log_verbose set AWS_KEY from the directory if it does not exist
		AWS_KEY_ID="${AWS_KEY_ID:-"$(cat "$AWS_KEY_DIR/$AWS_KEY_ID_FILE.$AWS_PROFILE")"}"
		AWS_KEY="${AWS_KEY:-"$(cat "$AWS_KEY_DIR/$AWS_KEY_FILE.$AWS_PROFILE")"}"
		if [[ -n $AWS_KEY_ID ]]; then
			log_verbose "setting aws_access_key_id to $AWS_KEY_ID for profile $AWS_PROFILE"
			aws configure set aws_access_key_id "$AWS_KEY_ID" --profile "$AWS_PROFILE"
		fi
		if [[ -n $AWS_KEY ]]; then
			log_verbose "setting aws_secret_access_key to $AWS_KEY for profile $AWS_PROFILE"
			aws configure set aws_access_key_id "$AWS_KEY" --profile "$AWS_PROFILE"
		fi
		log_verbose "if the above fails then get input interactively"
		if [[ ! -e $HOME/.aws/config || ! -e $HOME/.aws/credentials ]]; then
			log_warning you will now enter your AWS credentials
			log_warning "You need to create them at the AWS console then enter the secrets here"
			aws configure
		fi

	else

		# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/configure/sso.html
		log_verbose" Using Amazon sso for keys which are temporary and default"
		aws configure sso --profile "$AWS_PROFILE" \
			--sso-start-url "$AWS_SSO_START_URL" \
			--region "$AWS_SSO_REGION" \
			--endpoint-url "$AWS_SSO_ENDPOINT_URL"

	fi

	# obsolete, the new aws configure does all this work
	# if ! config_mark "$HOME/.aws/credentials" || $FORCE
	# then
	#     log_verbose adding credentials
	#     config_add "$HOME/.aws/credentials" <<-EOF
	# [default]
	# aws_access_key_id = $(cat "$AWS_FILES/aws-access-key-id")
	# aws_secret_access_key = $(cat "$AWS_FILES/aws-access-key")
	# EOF
	# fi

	log_verbose 600 is needed so credentials/restore-keys.py works
	chmod 600 "$HOME/.aws/config" "$HOME/.aws/credentials"

fi

# Sam's way of doing this same configuration using a deployment key kept in AWS
# Eventually we will also do it this way, but need a bootstrap set of keys first
# aws --profile $ORGNAME-build s3 cp s3://$AWS_ORG_NAME-deploy-keys/iam/$AWS_ORG_NAME-deploy.aws-configure.stdin /tmp/cfg.$$.tmp
# aws configure --profile $AWS_ORG_NAME-deploy < /tmp/cfg.$$.tmp > /dev/null
# rm /tmp/cfg.$$.tmp

if ! log_assert "aws s3 ls" "aws can access s3"; then
	log_warning "AWS keys are not correctly configured"
fi
