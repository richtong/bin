
#!/usr/bin/env bash
##
## configure zfs quotas
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

POOL="${POOL:-"zfs"}"
DATASETS="${DATASETS:-"data home"}"
# assume that /home has all the users we need
USERS="${USERS:-"$(sudo zfs userspace -H -o name $POOL/home)"}"
QUOTA="${QUOTA:-2T}"
USERQUOTA="${USERQUOTA:-500G}"
FORCE="${FORCE:-false}"
OPTIND=1
while getopts "hdvp:s:fq:u:m:" opt
do
    case "$opt" in
        h)
            echo "Configure zfs quotas for users and overall for datasets"
            echo "Users then get individual accounts in the $POOL/user and common"
            echo "by default likes in $POOL/data"
            echo
            echo "usage $SCRIPTNAME [flags]"
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -p pool (default: $POOL)"
            echo "       -s datasets (default: $DATASETS)"
            echo "       -f force quotas even if already set (default: $FORCE)"
            echo "       -q maximum size of a dataset (default: $QUOTA)"
            echo "       -u maximum space any one user use (default: $USERQUOTA)"
            echo "       -m the users getting quotas (default: $USERS)"
            echo
            echo "Use this after install-zfs.sh or if you lose the zfs pool"
            echo "after a major upgrade"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        p)
            POOL="$OPTARG"
            ;;
        s)
            DATASETS="$OPTARG"
            ;;
        f)
            FORCE=true
            ;;
        q)
            QUOTA="$OPTARG"
            ;;
        u)
            USERQUOTE="$OPTARG"
            ;;
        m)
            USERS="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-util.sh lib-install.sh lib-fs.sh

shift $((OPTIND-1))

if [[ ! $OSTYPE =~ linux ]]
then
    log_exit "Linux only"
fi

package_install members

## https://www.npmjs.com/package/onepass-cli for npm package
log_verbose Now add the overall quotas
for share in $DATASETS
do
    dataset="$POOL/$share"
    log_verbose the zfs dataset is $dataset

    log_verbose checking quota for $dataset already set
    if [[ $(zfs_list quota "$dataset") =~ none ]]
    then
        log_verbose no quota set so making it $QUOTA for $dataset
        sudo zfs quota="$QUOTA" "$dataset" >/dev/null
        log_assert "[[ $(zfs_list quota "$dataset") =~ $QUOTA ]]" "quota set on $dataset"
    fi

    log_verbose setting quotas for $USERS
    for user in $USERS
    do
        log_verbose looking at $user for $dataset
        if sudo zfs userspace -H -o name,quota $dataset | grep -q "^$user.*none"
        then
            log_verbose no quota set, so set $user to $USERQUOTA
            sudo zfs set userquota@$user=$USERQUOTA $dataset
        fi
    done
    if $VERBOSE
    then
        log_verbose user quotas for $dataset
        sudo zfs userspace $dataset
    fi
done

if $VERBOSE
then
    log_verbose dataset quotas
    sudo zfs list -o name,quota,used,avail,refer,mountpoint
fi


# http://docs.oracle.com/cd/E19253-01/819-5461/gazvb/
log_verbose to set maximum quotas and minumum reserve specific storage you
log_verbose can run these against the datasets
log_verbose sudo zfs set quota=200G reserve=20G $POOL/home
log_verbose to set a quota for specific user or group across a dataset
log_verbose sudo zfs set userquota@shonk=2T /home
log_verbose sudo zfs set groupquota@iam-users=4T $POOL/home
log_verbose to see all users and group
log_verbose sudo zfs userspace $POOL/home
