#!/usr/bin/env bash
# vim: set noet ts=4 sw=4:
#
## install  vscode and vscodium and other flavors
## @author Rich Tong
## @returns 0 on success
#
# https://chezmoi.io/
#
set -ueo pipefail && SCRIPTNAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR=${SCRIPT_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}
DEBUGGING="${DEBUGGING:-false}"
VERBOSE="${VERBOSE:-false}"
FORCE="${FORCE:-false}"
export FLAGS="${FLAGS:-""}"

OPTIND=1
while getopts "hdvf" opt; do
	case "$opt" in
	h)
		cat <<-EOF
			    Installs VSCode and VSCodium (the open source branch)
						usage: $SCRIPTNAME [ flags ]
						flags:
							   -h help
							   -d $($DEBUGGING && echo "no ")debugging
							   -v $($VERBOSE && echo "not ")verbose
							   -f $($FORCE && echo "do not ")force install even $SCRIPTNAME exists

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
	f)
		FORCE="$($FORCE && echo false || echo true)"
		export FORCE
		;;
	*)
		echo "no flag -$opt"
		;;
	esac
done
shift $((OPTIND - 1))
# shellcheck disable=SC1091
if [[ -e "$SCRIPT_DIR/include.sh" ]]; then source "$SCRIPT_DIR/include.sh"; fi
source_lib lib-git.sh lib-mac.sh lib-install.sh lib-util.sh lib-config.sh

if in_os mac; then

	log_verbose "Mac install"
fi

PACKAGE+=(
	visual-studio-code
	vscodium
)

log_verbose "Install ${PACKAGE[*]}"
package_install "${PACKAGE[@]}"

# https://stackoverflow.com/questions/35929746/automatically-install-extensions-in-vs-code
EXTENSION+=(

	amazonwebservices.amazon-q-vscode
	amazonwebservices.aws-toolkit-vscode
	asvetliakov.vscode-neovim
	charliermarsh.ruff
	christian-kohler.path-intellisense
	continue.continue
	davidanson.vscode-markdownlint
	dbaeumer.vscode-eslint
	eamodio.gitlens
	formulahendry.auto-close-tag
	formulahendry.code-runner
	github.vscode-pull-request-github
	golang.go
	james-yu.latex-workshop
	linuxsuren.api-testing
	mhutchie.git-graph
	ms-azuretools.vscode-docker
	ms-kubernetes-tools.vscode-kubernetes-tools
	ms-python.debugpy
	ms-python.isort
	ms-python.python
	ms-toolsai.jupyter
	ms-toolsai.jupyter-keymap
	ms-toolsai.jupyter-renderers
	ms-toolsai.vscode-jupyter-cell-tags
	ms-toolsai.vscode-jupyter-slideshow
	ms-vscode.live-server
	pkief.material-icon-theme
	redhat.vscode-yaml
	streetsidesoftware.code-spell-checker
	timonwong.shellcheck

)

for E in "${EXTENSION[@]}"; do
	log_verbose "Install $E"
	codium --install-extension "$E"
	code --install-extension "$E"
done

for S in "VSCodium" "Code"; do
	SETTING="$HOME/Library/Application Support/$S/User/settings.json"
	# in json two slashes are a comment
	if ! config_mark "$SETTING" "//"; then
		config_add "$SETTING" <<-EOF
			  {
			          "editor.accessibilitySupport": "off",
			          "editor.wordWrap": "bounded",
			          "files.autoSave": "onFocusChange",
			          "workbench.startupEditor": "none",
			          "security.workspace.trust.untrustedFiles": "open",
			          "amazonQ.telemetry": false,
			          "aws.telemetry": false,
			          "extensions.experimental.affinity": {
			            "asvetliakov.vscode-neovim": 1
			          }
			  }
		EOF
	fi
done
