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

# get command line options
OPTIND=1
FLAGS="${FLAGS:-""}"
FORCE=${FORCE:-false}
AWS_KEY_DIR="${AWS_KEY_DIR:-"$HOME/.ssh/"}"
AWS_KEY_ID_FILE="${AWS_KEY_ID:-"aws-access-key-id"}"
AWS_KEY_FILE="${AWS_KEY:-"aws-access-key"}"
AWS_REGION="${AWS_REGION:-"us-west-2"}"
AWS_OUTPUT_TYPE="${AWS_OUTPUT_TYPE:-"json"}"
SET_AWS_PROFILE="${SET_AWS_PROFILE:-"default"}"
ORG_NAME="${ORG_NAME:-"tongfamily"}"
while getopts "hdvi:k:fp:r:o:" opt; do
    case "$opt" in
        h)
            cat <<-EOF
Install the aws configuration parameters
        usage: $SCRIPTNAME [flags]
            -d : debug -h : help
            -a if SET_AWS_ID and SET_AWS_KEY are not set look in this directory for files (default: $AWS_KEY_DIR)
            -i the name of the access key identifier (default: $AWS_KEY_ID_FILE.$SET_AWS_PROFILE)
            -k the name of the access key (default: $AWS_KEY_FILE.$SET_AWS_PROFILE))
            -f force the installation of credentials and config
            -p set for a specific profile (default: $SET_AWS_PROFILE)
            -r aws region for services (default: $AWS_REGION)
            -o aws output type (default: $AWS_OUTPUT_TYPE)
EOF

            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            FLAGS+=" -v "
            ;;
        a)
            AWS_FILES="$OPTARG"
            ;;
        f)
            FORCE=true
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-config.sh

if ! command -v aws > /dev/null
then
    "$SCRIPT_DIR/install-aws.sh"
fi

# http://stackoverflow.com/questions/24542934/automating-bat-file-to-configure-aws-s3
mkdir -p "$HOME/.aws"

if [[ ! $FORCE && -e $HOME/.aws/credentials || -e $HOME/.aws/config ]]
then
    log_exit $HOME/.aws/credentials or config already exits will not overwrite
fi

# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
# can now use the aws configure command instead
log_verbose setting region to us-west2 and output to json
aws configure set region "$AWS_REGION" --profile "$SET_AWS_PROFILE"
aws configure set output "$AWS_OUTPUT_TYPE" --profile "$SET_AWS_PROFILE"

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

log_warning you should not backup ~/.aws/credentials into git
log_warning you can use a soft link to a Veracrypt file

log_verbose set AWS_KEY from the directory if it does not exist
AWS_KEY_ID="${AWS_KEY_ID:-"$(cat "$AWS_KEY_DIR/$AWS_KEY_ID_FILE.$SET_AWS_PROFILE")"}"
AWS_KEY="${AWS_KEY:-"$(cat "$AWS_KEY_DIR/$AWS_KEY_FILE.$SET_AWS_PROFILE")"}"

if [[ ! -z $AWS_KEY_ID ]]
then
    log_verbose setting aws_access_key_id to $AWS_KEY_ID for profile "$SET_AWS_PROFILE"
    aws configure set aws_access_key_id "$AWS_KEY_ID" --profile "$SET_AWS_PROFILE"
fi
if [[ ! -z $AWS_KEY ]]
then
    log_verbose setting aws_secret_access_key to $AWS_KEY for profile "$SET_AWS_PROFILE"
    aws configure set aws_access_key_id "$AWS_KEY" --profile "$SET_AWS_PROFILE"
fi

# obsolecte, the new aws configure does all this work
# if ! config_mark "$HOME/.aws/credentials" || $FORCE
# then
#     log_verbose adding credentials
#     config_add "$HOME/.aws/credentials" <<-EOF
# [default]
# aws_access_key_id = $(cat "$AWS_FILES/aws-access-key-id")
# aws_secret_access_key = $(cat "$AWS_FILES/aws-access-key")
# EOF
# fi
log_verbose if the above fails then get input interactively

    if [[ ! -e $HOME/.aws/config || ! -e $HOME/.aws/credentials ]]
    then
        log_warning you will now enter your AWS credentials
        log_warning You need to create them at the AWS console then enter the secrets here
            aws configure
        fi

        log_verbose 600 is needed so credentials/restore-keys.py works
        chmod 600 "$HOME/.aws/config" "$HOME/.aws/credentials"


        # Sam's way of doing this same configuration using a deployment key kept in AWS
        # Eventually we will also do it this way, but need a bootstrap set of keys first
        # aws --profile $ORGNAME-build s3 cp s3://$ORG_NAME-deploy-keys/iam/$ORG_NAME-deploy.aws-configure.stdin /tmp/cfg.$$.tmp
        # aws configure --profile $ORG_NAME-deploy < /tmp/cfg.$$.tmp > /dev/null
        # rm /tmp/cfg.$$.tmp

        if ! log_assert "aws s3 ls" "aws can access s3"
        then
            log_warning "AWS keys are not correctly configured"
        fi
