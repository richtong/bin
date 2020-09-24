#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
## Note we have to be carefully because on a new Mac
## we will only have bash 3.x and we could potentially not have full XCode
##
## Also does a migration if it fails
##
##install mac ports
##
## Uses brew to do it
##
##@author Rich Tong
##@returns 0 on success
#
set -u && SCRIPTNAME=$(basename $0)
trap 'exit $?' ERR
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}
# use associative arrays http://www.artificialworlds.net/blog/2012/10/17/bash-associative-array-examples/
# declare -A MYMAP=( [foo]=bar [baz]=quux [corge]=grault ) # Initialise all at once
# conditional assignment with :- does not seem to work
# also not clear how to just print all of of thenm ${DOWNLOAD[@]} does not work
# this does not seem to work in an interactive bash `declare -A foo`

SOURCE_URL="${SOURCE_URL:="https://github.com/macports/macports-base/releases/download"}"
RESTORE_URL="${RESTORE_URL:-"https://github.com/macports/macports-contrib/raw/master/restore_ports/restore_ports.tcl"}"
VERSION="${VERSION:-2.4.2}"
MAKE_URL="${MAKE_URL:-false}"
INSTALL_URL="${INSTALL_URL:-"https:/www.macports.org/install.php"}"
EXT="${EXT:-pkg}"
FORCE="${FORCE:-false}"
MIGRATION="${MIGRATION:-false}"
OPTIND=1
while getopts "hdvt:u:s:r:e:nfm" opt
do
    case "$opt" in
        h)
            cat <<-EOF

Installs Mac Ports
Usage: $SCRIPTNAME [ flags ]
        flags: -d debug, -h help
               -t download directory where Macports image is cached (default: $DOWNLOAD_DIR)
               -u url of package to download (default is from below)
               -m migrate existing port packages (default: $MIGRATION)
               -f force an uninstall and reinstall needed when MacOS updates (default: $FORCE)
               -i installation page url (default: $INSTALL_URL)

               by default we look on install web page work the first reference
	       must have an http reference the version somewhere and then the extension
	       (default: $INSTALL_URL)

               -n make a url and disable the extract from the macports install page the version we need
                  (default: $MAKE_URL)
                   If -n is specified then If exact name is not supplied construct from
                   -s main root of distribution (default: $SOURCE_URL)
                   -r version of Macports (default: $VERSION)
                   -e extension (default: $EXT)
EOF
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        t)
            DOWNLOAD_DIR="$OPTARG"
            ;;
        u)
            DOWNLOAD="$OPTARG"
            ;;
        n)
            MAKE_URL=true
            ;;
        s)
            SOURCE_URL="$OPTARG"
            ;;
        r)
            VERSION="$OPTARG"
            ;;
        e)
            EXT="$OPTARG"
            ;;
        f)
            FORCE=true
            ;;
        m)
            MIGRATION=true
            ;;
    esac
done

if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-config.sh lib-util.sh

if ! in_os mac
then
    log_exit "Mac only"
fi

if command -v port >/dev/null
then
    if ! port | grep "OS platform mismatch"
    then
        log_exit after OS upgrade make sure you have latest xcode and reinstall
    fi
    log_verbose macports needs migration
    MIGRATION=true
fi

log_verbose making sure xcode is installed properly
if ! xcode-select -p >/dev/null
then
    log_verbose install command tools
    sudo xcode-select --install
fi
# https://apple.stackexchange.com/questions/175069/how-to-accept-xcode-license
xcode_license_accept

log_verbose install Mac Ports with brew
"$SCRIPT_DIR/install-brew.sh"
package_install macports


#    they have changed from .bz2 to a .pkg as of 2017
#    EXT="${EXT:-.tar.bz2}"

DOWNLOAD_DIR=${DOWNLOAD_DIR:-"$WS_DIR/cache"}
log_verbose downloading into $DOWNLOAD_DIR

if ! command -v port
then
    log_verbose begin installation from Macports download site
    # This construct works as of Oct-2017
    # https://github.com/macports/macports-base/releases/download/v2.4.2/MacPorts-2.4.2-10.13-HighSierra.pkg
    if $MAKE_URL
    then
        DOWNLOAD="${DOWNLOAD:-"$SOURCE_URL/v$VERSION/MacPorts-$VERSION-$(mac_version)-$(mac_codename | tr -d ' ').$EXT"}"
    else
        log_verbose attempt to find the version number $(mac_version) with the extension $EXT
        DOWNLOAD="$(curl -L "$INSTALL_URL" | grep -m 1 $(mac_version) | grep -o "https://.*$EXT")"
    fi
log_verbose downloading from $DOWNLOAD and we should be done if it is pkg
download_url_open "$DOWNLOAD"
# the actual extension vs what we searched for
# https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
macports_extension=${DOWNLOAD##*.}
# returns: list of file extracted or downloaded
if [[ $macports_extension =~ tar.bz2 ]]
then
    macports_filename="$(basename "$DOWNLOAD")"
    log_verbose trying to compile from a tar.bz2
    pushd "$DOWNLOAD_DIR" >/dev/null
    # The build instructions may fail because there is no TCL see https://trac.macports.org/wiki/MavericksProblems
    # So use https://trac.macports.org/wiki/MavericksProblems
    # https://stackoverflow.com/questions/592620/how-to-check-if-a-program-exists-from-a-bash-script
    # sudo make install fails when it is called from mac-install.sh and not clear seems to be trying to run /bin/sh
    # seems as if the environment is somehow wrong, but do not have time to debug so use the package instead
    macports_dir="${macports_filename%.*}"
    if [[ ! -e "$macports_dir" ]]
    then
        tar xf "$macports_filename"
    fi
    # https://stackoverflow.com/questions/538504/uses-for-this-bash-filename-extraction-technique
    # note we use a single % because we only want the very last extension to be consumed as
    # the Macport file name has lots of periods in it
    pushd "$macports_dir" >/dev/null
    ./configure
    make
    # this next line fails depending on where it is called
    sudo make install
    popd >/dev/null
    # from the make file itself
    # http://stackoverflow.com/questions/4479579/bash-script-only-echo-line-to-bash-profile-once-if-the-line-doesnt-yet-exis
    log_verbose macports incorrectly puts path in .profile so source it from .bash_profile
    if ! config_mark
    then
        config_add <<<'[[ -e $HOME/.profile ]] && source $HOME/.profile'
    fi
    source_profile
    popd >/dev/null
fi
fi

log_assert "command -v port" "Port installed"

# MacPorts installs into /opt/local/bin, but it is not on the path by default
log_verbose source .profile from .bash_profile
if ! config_mark
then
config_add <<<'export PATH=$PATH:/opt/local/bin/'
log_verbose to use Mac Ports source .bash_profile
fi

if ! command -v port >/dev/null
then
log_verbose could not find the port command try sourcing
source_profile
fi


log_verbose checking to see if we need to migrate
if $MIGRATION && port installed | grep -v "No ports are installed"
then
# https://trac.macports.org/wiki/Migration
log_verbose port installed now migrating existing
installed_ports=$(mktemp)
port -qv installed > "$installed_ports"
sudo port -f uninstall installed
sudo rm -rf /opt/local/var/macports/build/*
download_url "$RESTORE_URL"
sudo tclsh "$WS_DIR/cache/$(basename "$RESTORE_URL")" "$installed_ports"
rm "$installed_ports"
fi

log_verbose selfupdate and upgrade outdated
# -N means non-interactive
sudo port -Nv selfupdate
# port upgrade returns error if nothing to upgrade os ignore that error
sudo port -N upgrade outdated || true

log_verbose to use port, source .bash_profile to get path to it
