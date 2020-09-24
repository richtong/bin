#!/usr/bin/env bash
##
## install Dropbox
## The above gets the latest bash on Mac or Ubuntu or Debian
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
VERBOSE_FLAG=${VERBOSE_FLAG:-" -v "}
VERBOSE=${VERBOSE:-false}
DEBUGGING=${DEBUGGING:-false}
while getopts "hdvw:" opt
do
    case "$opt" in
        h)
            echo
            echo usage: c$SCRIPTNAME [flags ]
            echo "flags: -d debug, -h help"
            echo "       -w WS directory"
            exit 0
            ;;
        d)
            export DEBUGGING=true
            ;;
        v)
            export VERBOSE=true
            export VERBOSE_FLAG=" -v "
            ;;
        w)
            WS_DIR="$OPTARG"
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-util.sh lib-install.sh lib-config.sh
shift $((OPTIND-1))

if in_os mac
then
    if [[ ! -e /Applications/Dropbox.app ]]
    then
        if ! cask_install dropbox
        then
            download_url_open "https://www.dropbox.com/downloading?os=mac" "Dropbox.dmg"
        fi
        log_error 1 "After install, synchronize Dropbox"
    fi
    log_exit "Dropbox already installed"
fi

if command -v dropbox
then
    log_exit "dropbox exists"
fi

if in_ssh
then
    dest="/usr/local/bin"
    log_verbose "Install headless with https://www.dropbox.com/install-linux" into $dest

    dropbox_tar="$WS_DIR/cache/dropbox.tar.gz"
    download_url "https://www.dropbox.com/download?plat=lnx.x86_64" "$dropbox_tar"
    # need the - in case flag is not set
    if [[ ! -e $dest/.dropbox-dist ]]
    then
        sudo tar $VERBOSE_FLAG -xf "$dropbox_tar" -C "$dest"
    fi

    if ! command -v dropbox.py
    then
        log_verbose download dropbox cli
        download_url "https://www.dropbox.com/download?dl=packages/dropbox.py"
        # https://www.lifewire.com/install-linux-command-4091911
        # -b backup
        # -C install unless already exists
        # -D mkdir all need directories
        # -m  set mode
        log_verbose download headless client
        sudo install $VERBOSE_FLAG -bCD -m 755 "$WS_DIR/cache/dropbox.py" "$dest"
    fi
    log_assert "command -v dropbox.py" "Dropbox.py installed"

    log_verbose asking dropbox.py to autostart although this is not working in 16.04
    dropbox.py autostart y
    log_verbose add to $HOME/.profile autostart
    if ! config_mark
    then
        log_verbose add starting the dropbox headless daemon
        # note we want only the daemon to run in the background so start a
        # subshell and dropbox.py status comes out on stderr
        # on ubuntu 16.04 dropbox.py running does not work so use this instead
        config_add <<-EOF
dropbox.py status 2>&1 | grep -vq \"isn.t running\" && (exec \"$dest/.dropbox-dist/dropboxd\" >/dev/null &)
EOF
        source_profile
    fi

    log_verbose run daemon and fill in the authentication using the provided url
    log_verbose this also starts the dropbox daemon
    # note we put in background because it will not stop running
    if dropbox.py status | grep -q "isn.t running"
    then
        log_error 2 "cannot start dropbox daemon"
    fi

    log_verbose wait for daemon to start populating and then remove all visible
        log_verbose if you want some personal ones then run dropbox.py exclude remove
            log_verbose waiting for directories to populate
            sleep 15
            log_verbose excluding all subdirectories of $HOME/Dropbox to speed up
            log_verbose if you need some then use dropbox.py exclude remove _directory_
                dropbox.py exclude add "$HOME/Dropbox"*
                log_verbose set autostart so on reboot we will still have dropbox although
                exit
            fi

            # https://linuxconfig.org/how-to-install-dropbox-client-on-debian-9-stretch-linux
            # this does not work non-free does not have nautilus dropbox
            if in_linux debian
            then
                "$SCRIPT_DIR/install-nonfree.sh"
            fi

            sudo apt-get update -y
            sudo apt-get install -y nautilus-dropbox

            # ubuntu 14.04 or lower or old version of dropbox did this automatically
            log_verbose start dropbox daemon and kick off the graphical interface
            dropbox start -i

            log_message note that with linux and using onelogin there is a bug
            log_message when you get to dropbox sign in the browser
            log_message you must use the upper right sign in and not the center
            log_warning Install and synchronize Dropbox before restarting script

            log_warning also make sure we see 'Dropbox' or 'Dropbox (Personal)'
