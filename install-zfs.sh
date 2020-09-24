##
## Install zfs and configure on our server
## Enables NFS and SMG/Samaba access
## https://www.latentexistence.me.uk/zfs-and-ubuntu-home-server-howto/
## main guide
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
# export these for use by functions that configure the rest
export POOL="${POOL:-"zfs"}"
export DATASETS="${DATASETS:-"data home"}"
export QUOTA="${QUOTA:-"1T"}"
export USERQUOTA="${USERQUOTA:-"500G"}"
export USERS="${USERS:-"$(members sambausers 2>/dev/null)"}"
ARC_MAX_FRACTION="${ARC_MAX:-"1/8"}"
DISKS="${DISKS:-""}"
CACHE="${CACHE:-""}"
LOGGER="${LOGGER:-""}"
FORCE="${FORCE:=""}"
SET_SMB_PASSWORD="${SET_SMG_PASSWORD:-false}"
USERS_TXT="${USERS_TXT:-false}"
flags=""
options=""
while getopts "hdvc:lp:s:a:fbq:u:x" opt
do
    case "$opt" in
        h)
            echo Install ZFS and configure ZFS, NFS and SMB

            echo "usage: $SCRIPTNAME [flags] [/dev/disk1 /dev/disk2...]"
            echo
            echo "flags: -d debug, -v verbose, -h help"
            echo "       -c quoted list of cache drives (default: ${CACHE:-none}"
            echo "       -l quoted list of logging drives (default: ${LOGGER:-none}"
            echo "       -p pool (default: $POOL)"
            echo "       -s quoted list of ZFS datasets in $POOL (defaults: $DATASETS)"
            echo "       -a max memory zfs arc should take in a fraction (default: $ARC_MAX_FRACTION)"
            echo "       -f force the change so overwrite existing (default: ${FORCE:-false})"
            echo "       -b set samba passwords (deprecated using sshfs instead) (default: $SET_SMB_PASSWORD)"
            echo "       -q maximum quota in each dataset (default: $QUOTA)"
            echo "       -u maximum drive space quota for each user (default: $USERQUOTA)"
            echo "       -m members of the file system (default: $USERS)"
            echo "       -x not using iam-key use old users.txt and groups.txt (default: $USERS_TXT)"
            echo
            echo "for ZFS use /dev/disk/by-id because on boot the /dev/sd? on non-VMware Fusion systems"
            echo "positionals: list of disks for zfs, valid names are:"
            echo
            # sed adds tabs to make it look nice
            # Note do not use the -a this takes 30 seconds on a real ubuntu machine
            "$SCRIPT_DIR/disk-info.sh"
            echo
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        c)
            CACHE="$OPTARG"
            ;;
        l)
            LOGGER="$OPTARG"
            ;;
        p)
            POOL="$OPTARG"
            ;;
        s)
            DATASETS="$OPTARG"
            ;;
        a)
            ARC_MAX_FRACTION="$OPTARG"
            ;;
        f)
            if [[ ! $flags =~ -f ]]
            then
                flags+=" -f "
            fi
            ;;
        b)
            SET_SMB_PASSWORD=true
            ;;
        q)
            QUOTA="$OPTARG"
            ;;
        u)
            USERQUOTA="$OPTARG"
            ;;
        m)
            USERS="$OPTARG"
            ;;
        x)
            USERS_TXT=true
            ;;
    esac
done
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-install.sh lib-util.sh lib-avahi.sh lib-util.sh lib-fs.sh lib-config.sh

shift $((OPTIND-1))
DISKS=${DISKS:-"$@"}

if [[ ! $OSTYPE =~ linux ]]
then
    log_error 1 "run on linux only"
fi

if ! command -v zfs > /dev/null
then
    case $(linux_distribution) in
        debian)
            # https://github.com/hn/debian-stretch-zfs-root/blob/master/debian-stretch-zfs-root.sh
            # The closest thing is buried in this script
            log_warning debian install is not tested
            "$SCRIPT_DIR/install-nonfree.sh"
            package_install zfs-dkms
            ;;

        ubuntu)
            case $(linux_version) in
                12*|14*)

                    if ! is_package_installed ubuntu-zfs
                    then
                        log_verbose on Ubuntu 14.40 need standalone repo
                        sudo apt-add-repository ppa:zfs-native/stable
                        sudo apt-get update
                        package_install ubuntu-zfs
                        mod_install zfs
                    fi
                    ;;
                15*|16*)
                    log_verbose part of native installation
                    # https://wiki.ubuntu.com/Kernel/Reference/ZFS
                    package_install zfsutils-linux
                    # https://wiki.ubuntu.com/ZFS but this actually just goes to
                    # zfsutils-line
                    # package_install zfs
                    ;;
                17*)
                    package_install zfsutils
                    ;;
                *)
                    log_warning Other Ubuntu $(linux_version) not supported
                    exit
                    ;;
            esac
            ;;
        *)
            log_exit do not how to installed this version of linux
                ;;
        esac

    fi

    # Manage the ZFS ARC cache
    # http://stackoverflow.com/questions/18808174/lost-memory-on-linux-not-cached-not-buffers/18808311#18808311
    # it defaults to 2/3 of available memory
    # http://discourse.ubuntu.com/t/zfs-vs-btrfs-experience/1648/3
    # We default to 1/4
    if ! grep -q zfs_arc_max /etc/modprobe.d/zfs.conf
    then
        # sets the limit to 24GB
        memtotal=$(cat /proc/meminfo | grep MemTotal | awk '{print $2}')
        log_verbose Total memory in machine $memtotal
        arc_max=$((memtotal * 1024 * $ARC_MAX_FRACTION))
        sudo tee -a /etc/modprobe.d/zfs.conf <<<"options zfs zfs_arc_max=$arc_max"
    fi


    if [[ -z $DISKS ]]
    then
        # the :- puts in the world no if disks_lists returns a null
        posssible=$(disks_list_possible)
        log_warning "No disks on the command line, ${possible:-no disks} currently available for allocation"
        log_warning "continue to configure $POOL"
    fi

    if ! disks_not_mounted $DISKS >/dev/null
    then
        log_verbose $? drives are already mounted skipping adding drives to a new pool
elif sudo zpool status "$POOL" 2>&1 | grep -q "pool: $POOL"
    then
        # look at the status of the first zpool call
        log_verbose "$POOL already exists so will not create"
    else
        log_verbose no zpool so try to create

        # vmware will need the force flag
        if in_vmware_fusion && [[ ! $flags =~ -f ]]
        then
            flags+="-f"
        fi

        layout=(zfs_disk_configuration $DISKS)
        log_verbose zfs disk configuration string is $layout

        # http://www.zfsbuild.com/2010/06/03/howto-zfs-add-log-drives-zil/
        # They recommend this be mirrored for fault tolerance
        if [[ -n $LOGGER ]] && disk_is_ssd $LOGGER
        then
            # http://unix.stackexchange.com/questions/65595/how-to-know-if-a-disk-is-an-ssd-or-an-hdd
            if (( $(echo $LOGGER | wc -w) == 1 ))
            then
                options+=" log $LOGGER"
            else
                options+=" log mirror $LOGGER"
            fi
        fi

        # http://serverascode.com/2014/07/03/add-ssd-cache-zfs.html
        # Note cache adds
        if [[ -n $CACHE ]] && disk_is_ssd $CACHE
        then
            options+=" cache $CACHE"
        fi

        # No quotes around flags or options as they are separate arguments to zpool
        sudo zpool create $flags "$POOL" $layout $options
        sudo zfs set compression=on "$POOL"
    fi


    # https://bugs.launchpad.net/ubuntu/+source/zfs-linux/+bug/1602409
    if ! is_package_installed zfs-auto-snapshot
    then
        log_verbose setup zfs-auto-snapshot as of Ubuntu 16.04.2 not in standard install
        repository_install ppa:bob-ziuchkovski/zfs-auto-snapshot
        package_install zfs-auto-snapshot
    fi

    # https://docs.oracle.com/cd/E19120-01/open.solaris/817-2271/gbcxl/
    log_verbose zfs-auto-snapshot by default creates a dataset snapshot every 15 minute
    log_verbose turn on with sudo zfs set com.sun:auto-snapshot=false $POOL/_dataset_
    log_verbose the defaults are:
    log_verbose frequent     snapshots every 15 mins, keeping 4 snapshots
    log_verbose hourly       snapshots every hour, keeping 24 snapshots
    log_verbose daily        snapshots every day, keeping 31 snapshots
    log_verbose weekly       snapshots every week, keeping 7 snapshots
    log_verbose monthly      snapshots every month, keeping 12 snapshot
    log_verbose change intervale zfs set com.sun:auto-snapshot:daily=true $POOL/_dataset_
    log_verbose we turn off frequent and hourly
    sudo zfs set com.sun:auto-snapshot:frequent=false


    # https://docs.oracle.com/cd/E19120-01/open.solaris/817-2271/gbcxl/
    log_assert "command -v zfs" "zfs installed"
    log_assert "command -v zpool" "zpool installed"

    log_verbose $SCRIPT_DIR/zfs-fix.sh if you lose zfs pools after an os upgrade

    log_verbose automount does not work reliably so manually import in the .profile
    # We need to run this in .profile which is used once for each boot of the ubuntu
    # system
    #
    # If you want to make sure that something runs when the machine boots, this is
    # trickier, you need to use systemd to do this and make sure the services you need
    # are in order (upstart on Ubuntu 14.04). This is why for instance zfs-fix.sh is
    # run in .profile, we are pretty sure at that point everything is loaded.
    # zfs-fix.sh is really a bandaid, the automount does not seem to work reliably
    # with zfs, so this is an additional check
    if ! config_mark "$HOME/.profile"
    then
        log_verbose adding zpool import to .profile since automount does not work
        config_add <<<"sudo zpool list \"$POOL\" >/dev/null || sudo zpool import \"$POOL\""
    fi

    # https://pthree.org/2012/12/31/zfs-administration-part-xv-iscsi-nfs-and-samba/
    # https://www.reddit.com/r/openzfs/comments/58eypa/ubuntu_1604x_zfs_auto_mount/?st=j5wxtxcy&sh=d4d0f001
    log_verbose zfs auto share and unshare on startup and shutdown needed in /etc/default

    config="/etc/default/zfs"
    if ! config_mark "$config"
    then
        config_add_once "$config" "# Made sure ZFS_SHARE, ZFS_UNSHARE set and ZFS_AUTOIMPORT_TIMEOUT long enough"
        # becareful how you deal with quotes need the double quotes to protect the
        # single ones also config_replace does add a new line as a side effect  that
        # @rich does not know how to fix
        # config_replace "$config" ZFS_SHARE "ZFS_SHARE='yes'"
        # config_replace "$config" ZFS_UNSHARE "ZFS_UNSHARE='yes'"
        # config_replace "$config" ZFS_AUTOIMPORT_TIME "ZFS_AUTOIMPORT_TIME='60'"
        # more natural to use variable set instead
        set_config_var ZFS_SHARE "'yes'" $config
        set_config_var ZFS_UNSHARE "'yes'" $config
        set_config_var ZFS_AUTOIMPORT_TIME "'60'" $config
    fi

    # hard to pass single quotes, need double escape as it goes through call and
    # then the grep
    log_assert "grep ^ZFS_AUTOIMPORT_TIME=.60 "$config"" "ZFS share auto mounts"
    log_assert "grep ^ZFS_SHARE=.yes "$config"" "ZFS shares automatically start"
    log_assert "grep ^ZFS_UNSHARE=.yes "$config"" "ZFS shares unmount on shutdown"

    log_verbose install nfs
    package_install nfs-kernel-server
    # http://askubuntu.com/questions/450971/zfs-on-linux-setting-up-nfs-on-ubuntu-14-04-with-os-x-mavericks-client
    # will not start with a null /etc/exports but  how to populate it?
    # https://pthree.org/2012/12/31/zfs-administration-part-xv-iscsi-nfs-and-samba/
    if ! config_mark /etc/exports
    then
        log_verbose dummy /etc/exports needed on ubuntu so mount /media to localhost on Ubuntu 14.04
        config_add_once /etc/exports "/media localhost(ro)"
    fi
    if sudo service nfs-kernel-server start | grep -q Starting
    then
        log_warning NFS could not start
    fi
    # https://pthree.org/2012/12/18/zfs-administration-part-xi-compression-and-deduplication/
    # http://askubuntu.com/questions/450971/zfs-on-linux-setting-up-nfs-on-ubuntu-14-04-with-os-x-mavericks-client
    # insecure because Macs connect above port 1024
    log_verbose start nfs sharing
    sudo zfs set sharenfs="rw,insecure" "$POOL"
    # do not need on as it override
    # sudo zfs set sharenfs=on "$POOL"

    # https://askubuntu.com/questions/450971/zfs-on-linux-setting-up-nfs-on-ubuntu-14-04-with-os-x-mavericks-client
    log_verbose NFS sharing is highly experimental there are many issues with permissions
    log_verbose and the protocol is insecure with Kerberos
    log_verbose to access from Mac try sudo mount -t nfs $HOSTNAME:/$POOL /Volumes/$POOL
    log_verbose see available ports with rpcinfo -p $HOSTNAME
    log_verbose see what nfs mounts are available with showmount -e $HOSTNAME

    log_verbose start SMB share
    package_install samba
    sudo zfs set sharesmb=on "$POOL"

    # https://www.hiroom2.com/2016/05/18/ubuntu-16-04-share-zfs-storage-via-nfs-smb/
    log_verbose smb started edit /etc/samab/smb.conf to allow usershare

    if $SET_SMB_PASSWORD
    then
        log_verbose set passwords as needed also sets login
        "$SCRIPT_DIR/set-passwd.sh"
    fi
    log_verbose start sharing
    # note |& not portable for Mac
    if sudo zfs share "$POOL" 2>&1 | grep "already started"
    then
        log_verbose $POOL already shared
    fi

    if ! in_linux ubuntu
    then
        log_verbose not in ubuntu assume we need to publish samba
        avahi_publish smb "$HOSTNAME Samba" _smb._tcp 445
    fi
    log_verbose publish nfs shares on avahi
    avahi_publish nfs "$HOSTNAME NFS" _nfs._tcp 2049 "path=/$POOL"
    # In ubuntu we do not automount
    # https://www.princeton.edu/~unix/Solaris/troubleshoot/zfs.html
    if $VERBOSE
    then
        log_verbose shares created
        sudo zfs list
        sudo zfs get sharesmb,sharenfs
        sudo zpool status
        if ! showmount -e
        then
            log_warning showmount failed could be that nfs is not started
        fi
    fi

    log_verbose basic pool created now chain to dataset, account and directory creation
    log_verbose zfs and zpool installed if you need shares
    "$SCRIPT_DIR/install-zfs-datasets.sh" -p "$POOL" -s "$DATASETS" -q "$QUOTA"

    # install-accounts used a table of users from ../etc
    # now instead assume we set up for everyone in an iam
log_verbose create all user accounts should now be done by iam-key
# install-accounts used if iam-user is not it uses users in ../etc/
if ! sudo service iam-key status | grep running
then
    log_exit Must use iam-key or run "$SCRIPT_DIR/install-accounts.sh"
fi

if $USERS_TXT
then
    log_verbose warning this is deprecated use iam-key instead
    "$SCRIPT_DIR/install-accounts.sh"
    "$SCRIPT_DIR/mkdir-accounts.sh" -r "/$POOL/user"
fi

"$SCRIPT_DIR/install-zfs-quotas.sh" -p "$POOL" -s "$DATASETS" -q "$QUOTA" -u "$USERQUOTA"
"$SCRIPT_DIR/install-zfs-auto-snapshot.sh" -p "$POOL"

log_verbose $SCRIPT_DIR/zfs-fix.sh if you lose zfs pools after an os upgrades
