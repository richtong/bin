#!/usr/bin/env bash
##
## Create a machine learning instance with Amazon AWS
##
## Moves secrets into a usb or a Dropbox
##
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
MACHINE=${MACHINE:-"$USER-ml"}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$(cat "$HOME/.ssh/aws-access-key-id")}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$(cat "$HOME/.ssh/aws-access-key")}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
export AWS_ZONE=${AWS_ZONE:-"c"}
export AWS_VPC_ID=${AWS_VPC_ID:-"vpc-234db146"}
export AWS_INSTANCE_TYPE=${AWS_INSTANCE_TYPE:-"g2.2xlarge"}
AWS_SPOT=${AWS_SPOI:-false}
# spot price arbitrarily set at 20% of the normal rate
# We do not turn on as normally these g2 instances do not go on sale
AWS_SPOT_PRICE=${AWS_SPOT_PRICE:-0.13}
AWS_REBUILD=${AWS_REBUILD:-false}
while getopts "hdvm:p:k:i:r:z:sc:x" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: create a AWS machine with tensorflow in it
            echo flags: -d debug -v verbose
            echo "       -m name of tensorflow machine (default: $MACHINE)"
            echo "       -p aws public access key (default: $AWS_ACCESS_KEY_ID)"
            echo "       -k aws private access key (default: $AWS_SECRET_ACCESS_KEY)"
            echo "       -i instance type (default: $AWS_INSTANCE_TYPE)"
            echo "       -r aws region (default: $AWS_DEFAULT_REGION)"
            echo "       -z aws xone (default: $AWS_ZONE)"
            echo "                 g2.2xlarge - 1 GPU 16GB \$0.65/hour on demand"
            echo "                 g2.8xlarge - 4 GPUs 60GB \$2.80/hour on demand"
            echo "       -s request spot instance (default $AWS_SPOT)"
            echo "       -c spot instance price (default $AWS_SPOT_PRICE)"
            echo "       -x delete current instance and rebuild (default: $AWS_REBUILD)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        m)
            MACHINE="$OPTARG"
            ;;
        s)
            AWS_SPOT_PRICE="0.065"
    esac
done

if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND-1))

if [[ $(uname) != Darwin ]]
then
    echo $SCRIPTNAME: only runs on a mac
    exit 0
fi

# https://docs.docker.com/machine/drivers/aws/
# Note that these are default definitions for AWS

# https://www.quora.com/What-is-the-difference-between-a-spot-instance-and-a-demand-instance-on-EC2
# spot instances are 10% the cost of ondemand

flags+=" --amazonec2-access-key "$AWS_ACCESS_KEY_ID" \
          --amazonec2-secret-key "$AWS_SECRET_ACCESS_KEY" \
          --amazonec2-vpc-id "$AWS_VPC_ID" \
          --amazonec2-region "$AWS_DEFAULT_REGION" \
          --amazonec2-zone "$AWS_ZONE" \
          --amazonec2-instance-type "$AWS_INSTANCE_TYPE" \
        "

if "$AWS_SPOT"
then
    log_warning Using AWS Spot instance means creation may wait for a long time
    flags+=" --amazonec2-request-spot-instance \
             --amazonec2-spot-price $AWS_SPOT_PRICE \
           "
fi

if "$AWS_REBUILD" && docker-machine status "$MACHINE" >/dev/null 2>&1
then
    docker-machine rm "$MACHINE"
fi

# Need the -f to force if there is an error
if docker-machine status "$MACHINE" 2>&1 | grep error > /dev/null
then
    log_warning if you have a missing instance id, the spot request maybe open
    log_warning so you need to also remove that at aws.amazon.com in Spot Requests
    docker-machine rm -f "$MACHINE"
fi

# Note that |& does not work in Macport or homebrew as of 4.3 and 4.4 so use 2>&1
if ! docker-machine status "$MACHINE" >/dev/null
then
    log_verbose docker-machine create with $flags
    if aws ec2 describe-key-pairs --key-name "$MACHINE"
    then
        if ! aws ec2 delete-key-pair --key-name "$MACHINE"
        then
            # http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-spot-instance-requests.html
            # http://www.compciv.org/recipes/cli/jq-for-parsing-json/
            if aws ec2 describe-spot-instance-requests | \
                jq '.SpotInstanceRequests[].LaunchSpecification.KeyName' | \
                grep "$MACHINE"
            then
                log_warning could not delete keypair for $MACHINE because Spot instance still exists
            fi
        fi
    fi
    docker-machine create --driver amazonec2 \
        $flags \
        "$MACHINE"
fi

if ! docker-machine status "$MACHINE" | fgrep Running >/dev/null
then
    docker-machine start "$MACHINE"
fi

# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/docker_run_gpu.sh
log_warning "Note tensorflow requires hacks to work properly on EC2 G2"

echo to access the machine \'$MACHINE\' run
echo "    \`docker-machine env $MACHINE\`"
echo Note that the docker machine does not appear in the vmware fusion app
echo To access it you should run
echo "     docker-machine ssh $MACHINE"
