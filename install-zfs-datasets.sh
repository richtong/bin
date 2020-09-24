#!/usr/bin/env bash
##
## configure zfs partitions, shares
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

POOL="${POOL:-"zfs"}"
# ZFS Datasets are equivalent to Samba shares or Linux mountpoints
DATASETS="${DATASETS:-"data home"}"
FORCE="${FORCE:-false}"
# by default zfs points are in the root
MOUNTDIR="${MOUNTDIR:-"/"}"
OPTIND=1
while getopts "hdvp:s:fm:" opt
do
    case "$opt" in
        h)
            echo "Configure zfs shares and accounts"
            echo "In ZFS, the hard disks are placed into pools (aka volume groups)"
            echo "The actual shares (aka subvolumes aka datasets)"
            echo "that users see are then placed on these pools"
            echo "Users then get individual accounts in the $POOL/user and common"
            echo "by default likes in $POOL/data"
            echo
            echo "usage $SCRIPTNAME [flags]"
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -p pool (default: $POOL)"
            echo "       -s shares (defaults: $DATASETS)"
            echo "       -f force mounting of shares and copy (default: $FORCE)"
            echo "       -m mount the datasets into directory (default: $MOUNTDIR)_"
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
        m)
            MOUNTDIR="$OPTARG"
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

# No longer using samba
# package_install members
# if ! members sambashare > /dev/null
# then
#     log_warning no members found in sambashare to enable data shearing edit iam-key.conf.yml
#fi

## https://www.npmjs.com/package/onepass-cli for npm package
log_verbose Now create the datasets aka subvolumes aka shares for
for share in $DATASETS
do
    dataset="$POOL/$share"
    log_verbose the zfs dataset is $dataset
    mountpoint=$(readlink -f "$MOUNTDIR/$share")
    log_verbose the normalize absolute path to is $mountpoint
    log_verbose checking to see if $dataset created
    if ! zfs_list name "$dataset" > /dev/null
    then
        log_verbose no "$dataset" so create it
        sudo zfs create "$dataset" > /dev/null
    fi
    log_assert "zfs_list name $dataset | grep $dataset" "$dataset created"

    if [[  $(zfs_list mountpoint "$dataset") == $mountpoint ]]
    then
        log_verbose $dataset mountpoint already correctly set to $mountpoint
        continue
    fi

    # http://www.oracle.com/technetwork/server-storage/solaris/storage-utils-141358.html
    # https://www.cyberciti.biz/faq/linux-unix-shell-check-if-directory-empty/
    if [[ -f $mountpoint ]]
    then
        if ! $FORCE
        then
            log_warning $mountpoint is a file and should be a directory
            continue
        fi
        log_warning removing $mountpoint because FORCE is set
        sudo rm -f $mountpoint
    fi

    sudo mkdir -p "$mountpoint"

    # https://www.cyberciti.biz/faq/linux-unix-shell-check-if-directory-empty/
    # use wc because it consumes the output
    if ! dir_empty "$mountpoint"
    then
        if ! $FORCE
        then
            log_warning $dataset cannot be mount to $mountpoint it already exist use -f to force
            continue
        fi

        if [[ -e $mountpoint.save ]]
        then
            log_warning Cannot backup the data skipping mount to $mountpoint
            continue
        fi
        # https://superuser.com/questions/37137/moving-files-on-linux-appending-existing-directories-in-destination
        sudo mv "$mountpoint" "$mountpoint.save"
        # need to immediately sym link because if this is /home, then the entire
        # script breaks as it loses access to things like ~
        sudo ln -s "$mountpoint.save" "$mountpoint"
        # https://askubuntu.com/questions/577035/mv-command-dont-overwrite-files
        # rsync -av --remove-sourece-file "$mountpoint" "$mountpoint.save"

        tempmount=$(zfs_list mountpoint $dataset)
        if [[ -z  ${tempmount-} ]]
        then
            tempmount="$(sudo mktemp -d)"
            log_verbose $dataset was not mounted use $tempmount as the point
            sudo zfs set mountpoint="$tempmount" "$dataset"
        fi
        log_verbose copy back saves data from $mountpoint.save to $tempmount for $dataset
        # https://serverfault.com/questions/43014/copying-a-large-directory-tree-locally-cp-or-rsync
        # https://ss64.com/bash/rsync_options.html
        # http://manpages.ubuntu.com/manpages/trusty/man1/rsync.1.html
        # -a archive preservers ownership etc. does most things but the rest are:
        # -H do the slow hard link copy work
        # -A preserve ACLs
        # -X preserve extended atttibutes
        # --no-compress since this just takes CPU
        # http://qdosmsq.dunbar-it.co.uk/blog/2013/02/rsync-to-slash-or-not-to-slash/
        # "rsync src dest" gives "src/dest/subfolders" so dest is a subdirectory of # dest
        # "rsync src dest/" same as above
        # "rsync src/ dest" gives you src/subfolders so it is like rsync src/* dest
        # https://unix.stackexchange.com/questions/67539/how-to-rsync-only-new-files
        # -u skip files on the destination which are newere
        flags+=" -aHXu "
        if $VERBOSE || $DEBUGGING
        then
            # -P is --partial keep partial files and show progress
            flags+=" -P "
        fi
        sudo rsync $flags "$mountpoint.save/" "$tempmount"
        log_verbose copy complete
        log_verbose do the mount swapparoo getting rid of symlink if needed
            log_verbose there is a window where $mountpoint will not be available
            log_verbose remove $mountpoint link
            sudo rm $mountpoint
        fi

        sudo mkdir -p "$mountpoint"
        sudo zfs set "mountpoint=$mountpoint" "$dataset"
        if [[ -e ${tempmount-} ]]
        then
            sudo rmdir "$tempmount"
        fi
        log_verbose successfully copied $mountpoint onto the new $dataset and the
        log_verbose original data is saved in $mountpoint.save

    done

    log_verbose when shares are created, they inherit their sharenfs and sharesmb status

    # https://www.princeton.edu/~unix/Solaris/troubleshoot/zfs.html
    if $VERBOSE
    then
        log_verbose shares created
        sudo zfs list
        sudo zfs get sharesmb,sharenfs
        sudo zpool status
        showmount -e
    fi
