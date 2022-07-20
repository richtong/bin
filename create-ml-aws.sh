#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## Create a machine learning instance with Amazon AWS
##
## Moves secrets into a usb or a Dropbox
##
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}

OPTIND=1
MACHINE=${MACHINE:-"$USER-ml"}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-$(cat "$HOME/.ssh/aws-access-key-id")}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-$(cat "$HOME/.ssh/aws-access-key")}
export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
export AWS_ZONE=${AWS_ZONE:-"c"}
export AWS_VPC_ID=${AWS_VPC_ID:-"vpc-234db146"}
export AWS_INSTANCE_TYPE=${AWS_INSTANCE_TYPE:-"g2.2xlarge"}
AWS_SPOT=${AWS_SPOT:-false}
# spot price arbitrarily set at 20% of the normal rate
# We do not turn on as normally these g2 instances do not go on sale
AWS_SPOT_PRICE=${AWS_SPOT_PRICE:-0.13}
AWS_REBUILD=${AWS_REBUILD:-false}
while getopts "hdvm:p:k:r:z:sxi:c:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: create a AWS machine with tensorflow in it
			    flags:
				-d debug $($DEBUGGING && echo "off" || echo "on")
				-v verbose $($VERBOSE && echo "off" || echo "on")
			    -m name of tensorflow machine (default: $MACHINE)
			    -p aws public access key (default: $AWS_ACCESS_KEY_ID)
			    -k aws private access key (default: $AWS_SECRET_ACCESS_KEY)
			    -i instance type (default: $AWS_INSTANCE_TYPE)
			    -r aws region (default: $AWS_DEFAULT_REGION)
			    -z aws xone (default: $AWS_ZONE)
			        g.2xlarge - 1 GPU 16GB \$0.65/hour on demand
			        g2.8xlarge - 4 GPUs 60GB \$2.80/hour on demand
			    -s request spot instance (default $AWS_SPOT)
			    -c spot instance price (default $AWS_SPOT_PRICE)
			    -x delete current instance and rebuild (default: $AWS_REBUILD)
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
	m)
		MACHINE="$OPTARG"
		;;
	p)
		AWS_ACCESS_KEY_ID="$OPTARG"
		;;
	k)
		AWS_SECRET_ACCESS_KEY="$OPTARG"
		;;
	i)
		AWS_INSTANCE_TYPE="$OPTARG"
		;;
	r)
		AWS_DEFAULT_REGION="$OPTARG"
		;;
	z)
		AWS_ZONE="$OPTARG"
		;;
	s)
		AWS_SPOT=true
		;;
	c)
		AWS_SPOT_PRICE="0.065"
		;;
	x)
		AWS_REBUILD=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done

# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND - 1))

if [[ $(uname) != Darwin ]]; then
	log_exit 0 "$SCRIPTNAME: only runs on a mac"
fi

# https://docs.docker.com/machine/drivers/aws/
# Note that these are default definitions for AWS

# https://www.quora.com/What-is-the-difference-between-a-spot-instance-and-a-demand-instance-on-EC2
# spot instances are 10% the cost of ondemand

flags+="--amazonec2-access-key $AWS_ACCESS_KEY_ID
        --amazonec2-secret-key $AWS_SECRET_ACCESS_KEY
        --amazonec2-vpc-id $AWS_VPC_ID
        --amazonec2-region $AWS_DEFAULT_REGION
        --amazonec2-zone $AWS_ZONE
        --amazonec2-instance-type $AWS_INSTANCE_TYPE
       "

if "$AWS_SPOT"; then
	log_warning "Using AWS Spot instance means creation may wait for a long time"
	flags+=" --amazonec2-request-spot-instance
             --amazonec2-spot-price $AWS_SPOT_PRICE
           "
fi

if "$AWS_REBUILD" && docker-machine status "$MACHINE" >/dev/null 2>&1; then
	docker-machine rm "$MACHINE"
fi

# Need the -f to force if there is an error
if docker-machine status "$MACHINE" 2>&1 | grep error >/dev/null; then
	log_warning when there is a missing instance id, the spot request maybe open
	log_warning so you need to also remove that at aws.amazon.com for Spot Requests
	docker-machine rm -f "$MACHINE"
fi

# Note that |& does not work in Macport or homebrew as of 4.3 and 4.4 so use 2>&1
if ! docker-machine status "$MACHINE" >/dev/null; then
	log_verbose "docker-machine create with $flags"
	if aws ec2 describe-key-pairs --key-name "$MACHINE" && ! aws ec2 delete-key-pair --key-name "$MACHINE"; then
		# http://docs.aws.amazon.com/cli/latest/reference/ec2/describe-spot-instance-requests.html
		# http://www.compciv.org/recipes/cli/jq-for-parsing-json/
		if aws ec2 describe-spot-instance-requests |
			jq '.SpotInstanceRequests[].LaunchSpecification.KeyName' |
			grep "$MACHINE"; then
			log_warning "could not delete keypair for $MACHINE because Spot instance still exists"
		fi
	fi
	# shellcheck disable=SC2086
	docker-machine create --driver amazonec2 \
		$flags \
		"$MACHINE"
fi

if ! docker-machine status "$MACHINE" | grep Running >/dev/null; then
	docker-machine start "$MACHINE"
fi

# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/docker/docker_run_gpu.sh
log_warning "Note tensorflow requires hacks to work properly on EC2 G2"

echo "to access the machine \'$MACHINE\' run"
echo "    \`docker-machine env $MACHINE\`"
echo Note that the docker machine does not appear in the vmware fusion app
echo To access it you should run
echo "     docker-machine ssh $MACHINE"
