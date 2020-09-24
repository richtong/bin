#!/usr/bin/env bash
##
## Connects Terrafrom on the local machine to Gcloud
## Creates a service account and preps the projects
## https://cloud.google.com/community/tutorials/managing-gcp-projects-with-terraform
##
##@author Rich Tong
##@returns 0 on success
#
# To enable compatibility with bashdb instead of set -e
# https://marketplace.visualstudio.com/items?itemName=rogalmic.bash-debug
# use the trap on ERR
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
BILLING="${BILLING:-""}"
ACCOUNT="${ACCOUNT:-"terraform"}"
PROJECT_SUFFIX="${PROJECT_SUFFIX:-"terraform-admin"}"
SECRET_DIR="${SECRET_DIR:-"$HOME/.config/gcloud/secrets"}"
# project must be unique
# this replace set -e by running exit on any error use for bashdb
trap 'exit $?' ERR
OPTIND=1
export FLAGS="${FLAGS:-""}"
while getopts "hdvb:s:a:o:p:k:" opt
do
    case "$opt" in
        h)
            cat <<-EOF
Installs Google Cloud and components
    usage: $SCRIPTNAME [ flags ]
    flags: -d debug, -v verbose, -h help"
           -b billing account number
           -o project prefix (default is github orgname of current directory)
           -s project suffix (default: $PROJECT_SUFFIX)
           -p if you want to override the creation of the name
              (default: githuborgname-$PROJECT_SUFFIX)
           -a service account which does not to be uniquer (default: $ACCOUNT)
           -k secrets for service accounts storage (default: $SECRET_DIR)
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
        b)
            BILLING="$OPTARG"
            ;;
        s)
            PROJECT_SUFFIX="$OPTARG"
            ;;
        o)
            PROJECT_PREFIX="$OPTARG"
            ;;
        p)
            PROJECT="$OPTARG"
            ;;
        a)
            ACCOUNT="$OPTARG"
            ;;
        k)
            SECRET_DIR="$OPTARG"
            ;;
    esac
done
shift $((OPTIND-1))
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi

source_lib lib-install.sh lib-util.sh lib-config.sh lib-git.sh

if ! in_os mac
then
    log_warning "Not tested beyond MacOS"
fi

if [[ ! -v ORG ]]
then
    # https://cloud.google.com/blog/products/gcp/filtering-and-formatting-fun-with
    # note to determine valid fields, run with --format=json to see field names
    log_verbose find the first organization available which is a numeric code
    ORG="$(gcloud organizations list --format="value(name)" | head -1)"
fi
log_verbose using $ORG gcloud organization

if [[ ! -v BILLING ]]
then
    log_verbose querying for first billing account which is a numeric code
    BILLING="$(gcloud beta billing accounts list --format="value(name)" | head -1 )"
fi
log_verbose you are billing against $BILLING the first billing account found

PROJECT_PREFIX="${PROJECT_PREFIX:-"$(git_organization)"}"
PROJECT="${PROJECT:-"$PROJECT_PREFIX-$PROJECT_SUFFIX"}"
log_verbose seeing if a project named $PROJECT already exists

if [[ $(gcloud projects list --filter="projectId:$PROJECT" | wc -l ) < 2 ]]
then
    log_verbose no project $PROJECT exists so create one this may still fail if somewhere else in GCP there is one
    log_verbose note that project id must be unique across the entire google cloud namespace
    # https://stackoverflow.com/questions/52561383/gcloud-cli-cannot-create-project-the-project-id-you-specified-is-already-in-us
    # https://stackoverflow.com/questions/51391530/gcloud-command-to-check-if-project-exists
    if ! gcloud projects create "$PROJECT" --organization "$ORG" --set-as-default
    then
        log_error 1 "Project $PROJECT already exists somewhere in Google Cloud find another GUID and set with -p"
    fi
fi

log_verbose seeing if $PROJECT project uses $BILLING account
if [[ $(gcloud beta billing projects describe "$PROJECT" --format="value(billingAccountName)" | wc -l) < 1 ]]
then
    log_verbose linking $BILLING account to $PROJECT project
    gcloud beta billing projects "$PROJECT" --billing-account "$BILLING"
fi

log_verbose $BILLING account linked to $PROJECT

log_verbose create a Terrafrom Service account and get its credentials using
account_email="$ACCOUNT@$PROJECT.iam.gserviceaccount.com"
log_verbose will create an $account_email email
if [[ $(gcloud iam service-accounts list \
      --filter="email:$account_email" | wc -l) < 2 ]]
            then
                # https://linuxhint.com/bash_lowercase_uppercase_strings/
                # capitalize the account  name
                gcloud iam service-accounts create "$ACCOUNT"  \
                    --display-name "${ACCOUNT^} admin account"
            fi

            # check to make sure that the secrets are going in the home directory
            if [[ ! $(readlink -f "$SECRET_DIR") =~ ^$(readlink -f "$HOME") ]]
            then
                log_error 1 "cannot store into $SECRET_DIR must be within $HOME"
            fi

            log_verbose make sure $SECRET_DIR exits
            mkdir -p "$SECRET_DIR"
            secret="$SECRET_DIR/$account_email.json"
            log_verbose looking for $secret
            if [[ ! -e $secret ]]
            then
                log_verbose getting the secrete for $account_email email
                gcloud iam service-account keys create "$secret"  \
                    --iam-account "$account_email"

            fi
