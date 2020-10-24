#!/usr/bin/env bash
#
# Create hash files for comparison
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
while getopts "hdvns:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			$SCRIPTNAME: Create hashes for a set of files or directories
			parameters: [file list]
			flags: -d debug, -h help -v verbose
			       -s haShdeep flags (default: $HASHFLAGS)
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

error=0
log_verbose now create the hash
# https://stackoverflow.com/questions/255898/how-to-iterate-over-arguments-in-a-bash-script
for dir in "$@"; do
	if [[ ! -d "$dir" ]]; then
		log_verbose "$dir is not a directory skipping"
		continue
	fi
	if (($(find "$dir" | wc -l) <= 1)); then
		log_verbose "nothing in $dir skipping"
		continue
	fi
	log_verbose "going to $dir"
	if ! pushd "$dir" >/dev/null; then
		log_warning "no $dir skipping"
	fi
	hashfile="$(dirname "$dir")/$(basename "$dir").hashdeep"
	log_verbose "hash file is $hashfile"
	log_verbose "running hashdeep $HASHFLAGS * > $hashfile"
	# shellcheck disable=SC2086
	if ! hashdeep $HASHFLAGS ./* >"$hashfile"; then
		log_warning hashdeep on $dir failed continuing
		# must preincrement because a zero return is an error and halts the script
		((++error))
		continue
	fi

	popd >/dev/null || true
	# https://stackoverflow.com/questions/29244351/how-to-sort-a-file-in-place
	# inplace sorting  does not work because of header lines
	# sort -o "$dir.hashdeep" "$dir.hashdeep"
	# https://stackoverflow.com/questions/14562423/is-there-a-way-to-ignore-header-lines-in-a-unix-sort
	# This line only works if the format doesn't change
	# tail -n +5 "$dir.hashdeep" | sort > "$dir.hashdeep.sorted"
	log_verbose ignore the all lines beginning with % and hopefully that is all
	# https://stackoverflow.com/questions/26568952/how-to-replace-multiple-patterns-at-once-with-sed
	# https://stackoverflow.com/questions/1665549/have-sed-ignore-non-matching-lines
	if ! sed -n '/^[%#]/!p' "$hashfile" >"$hashfile.sorted"; then
		log_warning sed could not read "$hashfile" continuing
		((++error))
		continue
	fi

	# https://stackoverflow.com/questions/29244351/how-to-sort-a-file-in-place
	log_verbose "sorting $dir.hashdeep.sorted"
	if ! sort -o "$hashfile.sorted" "$hashfile.sorted"; then
		log_warning "sorting of $hashfile failed continuing"
		((++error))
		continue
	fi
done

log_verbose "$error errors occurred"
exit "$error"
