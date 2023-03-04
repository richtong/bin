#!/usr/bin/env bash
## vim: set noet ts=4 sw=4:
##
## install Anaconda for Mac only
## https://medium.com/ayuth/install-anaconda-on-macos-with-homebrew-c94437d63a37
##
##@author Rich Tong
##@returns 0 on success
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
OPTIND=1
NOFORGE="${NOFORGE:-false}"
PYTHON="${PYTHON:-3.9}"
ANACONDA="${ANACONDA:-miniconda}"
CONDA_BIN="${CONDA_BIN:-$HOME/miniconda3}"
URL="${URL:-https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh}"
VERSION="${VERSION:-2020.11}"
export FLAGS="${FLAGS:-""}"
while getopts "hdvacfp:r:u:" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			Installs Miniconda (you can install anaconda but more dependency issues)
			    usage: $SCRIPTNAME [ flags ]
			    flags: -h help"
			           -d $(! $DEBUGGING || echo "no ")debugging
			           -v $(! $VERBOSE || echo "not ")verbose
			           -a install full Anaconda (default: not $ANACONDA)
					   -c do not install conda-forge (default: $NOFORGE)
					   -p install python version (default: $PYTHON)
					   -r install anaconda version (default: $VERSION)
					   -u install miniconda version from (default: $URL)
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
	c)
		NOFORGE=true
		;;
	f)
		ANACONDA=anaconda
		URL="https://repo.anaconda.com/archive/Anaconda3-$VERSION-Linux-x86_64.sh"
		;;
	p)
		PYTHON="$OPTARG"
		;;
	r)
		VERSION="$OPTARG"
		;;
	u)
		URL="$OPTARG"
		;;
	*)
		echo "no -$opt flag" >&2
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck source=./include.sh
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

log_warning "link $HOME/.local/bin/gcc to gcc-version but this break Ubuntu"
if in_os mac; then
	log_verbose "In Mac install trying to install $ANACONDA"
	cask_install "$ANACONDA"
	log_verbose "$ANACONDA installed"
elif ! command -v conda &>/dev/null; then
	log_verbose "downloading $URL and running it"
	# https://docs.continuum.io/anaconda/install/linux/
	download_url "$URL"
	log_verbose "run script make sure to run conda init"
	if [[ ! -e $CONDA_BIN ]]; then
		log_verbose "install $CONDA_BIN"
		bash "$WS_DIR/cache/$(basename "$URL")"
	fi
fi

log_verbose "install conda into .zshrc"
if ! config_mark "$(config_profile_interactive_zsh)"; then
	config_add "$(config_profile_interactive_zsh)" <<-'EOF'
		# >>> conda initialize >>>
		# !! Contents within this block are managed by 'conda init' !!
		__conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
		if [ $? -eq 0 ]; then
			eval "$__conda_setup"
		else
			if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
				. "$HOME/miniconda3/etc/profile.d/conda.sh"
			else
				export PATH="$HOME/miniconda3/bin:$PATH"
			fi
		fi
		unset __conda_setup
		# <<< conda initialize <<<
	EOF
fi

log_verbose "source $(config_profile_interactive_bash) to make sure conda setup runs"
source_profile "$(config_profile_interactive_bash)"
log_verbose "source successful"

if ! $NOFORGE; then
	conda config --env --add channels conda-forge
	conda config --env --set channel_priority strict
fi

# return true in case there are errors in the source
conda init "$(basename "$SHELL")"
log_verbose take all the updates

# https://github.com/conda/conda/issues/9589
# Need this for a bug in 4.8.3
log_verbose get latest anaconda and packages
conda update conda --all -y
conda install "python=$PYTHON"

log_debug "do not conda on by default"
if ! config_mark "$(config_profile_nonexportable)"; then
	config_add "$(config_profile_nonexportable)" <<-'EOF'
		if command -v conda >/dev/null && [[ -v CONDA_SHLVL ]] && (( CONDA_SHLVL > 0 )); then conda deactivate; fi
	EOF
fi

if ! config_mark "$(config_profile_zsh)"; then
	config_add "$(config_profile_zsh)" <<-'EOF'
		if command -v conda >/dev/null; [[ -v CONDA_SHLVL ]] && (( CONDA_SHLVL > 0 )); then conda deactivate; fi
	EOF
fi

# log_warning "you should not install into base create your own environment"
# if [[ -v CONDA_SHLVL ]] && ((CONDA_SHLVL > 0)); then
# 	log_warning "currently in conda so deactivate"
# 	conda deactivate
# fi
