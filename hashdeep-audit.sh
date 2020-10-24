#!/usr/bin/env bash
#
# Rsync over a directory to a target
# Creates the hashes for file systems
# check the hashdeep
# Then mac only
#
set -u && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
trap 'exit $?' ERR

OPTIND=1

# http://manpages.ubuntu.com/manpages/xenial/man1/hashdeep.1.html
# -c sha256 is less vulnerable to hash hackign
# -k use for audit mode
# -e progress indicator
# -o fl only regular files and symbolic links are processed
# -r recursive search through directories
# -l relative names
# HASHFLAGS="${HASHFLAGS:=" -c sha256 -rl -o fl "}"
HASHFLAGS="${HASHFLAGS:=" -c sha256 -rl "}"
AUDIT="${AUDIT:-false}"
while getopts "hdvns:a" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Copy from source to destination and do a hashdeep comparision
			parameters: source destination
			flags: -d debug, -h help -v verbose
			       -s haShdeep flags (default: $HASHFLAGS)
			       -a ignore the special files do a full audit (default: $AUDIT)
		EOF
		exit 0
		;;
	d)
		export DEBUGGING=true
		;;
	v)
		export VERBOSE=true
		;;
	s)
		HASHFLAGS="$OPTARG"
		;;
	a)
		AUDIT=true
		;;
	*)
		echo "no -$opt" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e $SCRIPT_DIR/include.sh ]]; then source "$SCRIPT_DIR/include.sh"; fi
# source_lib lib-config.sh

if [[ ! $OSTYPE =~ darwin ]]; then
	log_exit Mac only
fi

# https://stackoverflow.com/questions/5265702/how-to-get-full-path-of-a-file
# make sure that they both exist or readlink will fail
if [[ ! -e $1 ]]; then
	log_error 1 "Source does not exist $1"
fi
log_verbose source exists
SRC="$(readlink -f "$1")"
log_verbose "source is $SRC"
log_verbose "making sure we have the destination $2"
mkdir -p "$2"
DST="$(readlink -f "$2")"
log_verbose "destination is $DST"
log_verbose "get the full path names of $SRC and $DST"

if [[ ! -e $DST.hashdeep.sorted ]]; then
	log_error 2 "no $DST.hashdeep.sorted have you run hashdeep_create.sh"
fi

if [[ ! -e $SRC.hashdeep.sorted ]]; then
	log_error 2 "no $SRC.hashdeep.sorted have you run hashdeep_create"
fi

log_verbose now auditing look for lines that are only in one file
# https://stackoverflow.com/questions/11099894/comparing-two-unsorted-lists-in-linux-listing-the-unique-in-the-second-file
# log_verbose now compare the files first sorting, and seeing if they are identical
# suppress all lines that are in both files (that is column 3)
if ! comm -3 "$DST.hashdeep.sorted" "$SRC.hashdeep.sorted"; then
	log_verbose seeing what diff says ignore diff error
	if ! diff "$DST.hashdeep.sorted" "$SRC.hashdeep.sorted"; then
		log_verbose "diff shows files are different do the full check"
	fi
fi

if $AUDIT; then
	log_verbose now check the hashs against it recomputing hashes
	# http://md5deep.sourceforge.net/hashdeep.html
	# -a audit comparing fails if not exact
	# -vv discrepances and which files
	if ! pushd "$DST" >/dev/null; then
		log_error 3 "no $DST"
	fi
	log_verbose "hashdeep $HASHFLAGS -a -vv -k $SRC.hashdeep"
	# https://github.com/koalaman/shellcheck/wiki/SC2035
	# ignore error if there are not flags so do not prevent globbing
	# shellcheck disable=SC2086
	hashdeep $HASHFLAGS -a -vv -k "$SRC.hashdeep" ./*
	popd >/dev/null || true
fi
