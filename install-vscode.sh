#!/usr/bin/env bash
## The above gets the latest stable release of Visual Studio Code for Linux
##
set -e && SCRIPTNAME=$(basename $0)
SCRIPT_DIR=${SCRIPT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"}

curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /var/tmp/microsoft.gpg
sudo mv /var/tmp/microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64] http://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'

sudo apt-get update
sudo apt-get install -y code # or code-insiders

#Install extensions
code --install-extension ms-vscode.cpptools
code --install-extension donjayamanne.python

code --list-extensions

#code --uninstall-extension ms-vscode.csharp

exit

OPTIND=1
while getopts "hdvr:" opt
do
    case "$opt" in
        h)
            echo $SCRIPTNAME: Install vscode
            echo "flags: -d debug, -h help"
            echo "       -r git lfs version (default $VERSION)"
            exit 0
            ;;
        d)
            DEBUGGING=true
            ;;
        v)
            VERBOSE=true
            ;;
    esac
done
