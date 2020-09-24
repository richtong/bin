#!/usr/bin/env bash
## The above gets the latest bash on Mac or Ubuntu
##
## Copy prebuild source files from ws/src/git
## Copy prebuild secrets from Dropbox into a USB key
##
#
set -e && SCRIPTNAME=$(basename "${BASH_SOURCE[0]}")
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

OPTIND=1
INPUT_ENCRYPTED_DIR=${INPUT_ENCRYPTED_DIR:-"$HOME/Dropbox/.Private"}
OUTPUT_ENCRYPTED_DIR=${OUTPUT_ENCRYPTED_DIR:-$(find "/media/$USER" -maxdepth 5 -name .Private)}
while getopts "hdvi:o:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: install encryption for ~/Private and others
            echo flags: -d debug -v verbose
            echo "       -i copy from an arbitrary directory"
            echo "          default is $INPUT_ENCRYPTED_DiR"
            echo "       -o or optionally copy into a specific encrypted directory"
            echo "          default is optionally copy into USB key $OUTPUT_ENCRYPTED_DIR"
            echo "Insert USB Key before running this and assumes mount points are Private"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
        i)
            INPUT_ENCRYPTED_DIR="$OPTARG"
            ;;
        o)
            OUTPUT_ENCRYPTED_DIR="$OPTARG"
            ;;
    esac
done
OUTPUT_MOUNTPOINT=${OUTPUT_MOUNTPOINT:-"$(dirname $OUTPUT_ENCRYPTED_DIR)/Private"}
INPUT_MOUNTPOINT=${INPUT_MOUNTPOINT:-"$(dirname $INPUT_ENCRYPTED_DIR)/Private"}


if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi

set -u
shift $((OPTIND-1))

# http://linuxpoison.blogspot.com/2010/10/how-to-use-ecryptfs-cryptographic.html
if ! command -v ecryptfs-setup-private
then
    sudo apt-get install -y ecryptfs-utils
fi

"$SCRIPTDIR/mount-ecryptfs.sh" "$INPUT_ENCRYPTED_DIR" "$INPUT_MOUNTPOINT"
"$SCRIPTDIR/mount-ecryptfs.sh" "$OUTPUT_ENCRYPTED_DIR" "$OUTPUT_MOUNTPOINT"

# Use rsync to make sure we get the latest files on each it is multimaster
rsync -abv "$INPUT_MOUNTPOINT/" "$OUTPUT_MOUNTPOINT"
