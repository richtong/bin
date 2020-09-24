#!/usr/bin/env python2.7

"""@package install-vim

    Automatic installation of vim and it"s packages
    Rich learning to write python
"""

import sys
import os

# Need expanduser to interpret the ~ in filenames
import logging
import argparse

# http://bugs.python.org/issue23223
try:
    import subprocess32 as subprocess
except ImportError:
    import subprocess
from time import strftime, gmtime
from os.path import expanduser


def main(args):
    """Parse command line arguments and run it for asingle file

    @param args command line
    """

    logging.basicConfig(level=logging.DEBUG)
    logging.debug("Main arguments: %s", args)

    # https://docs.python.org/2/howto/argparse.html
    parser = argparse.ArgumentParser(description="Install Vim and Packages")

    parser.add_argument(
        "-d",
        "--debug",
        default=False,
        action="store_true",
        help="turn on logging",
    )

    args = parser.parse_args()

    if args.debug:
        logging.info("Debug on, got arguments: %s", args)

    logging.debug("set variables")
    home = os.path.expanduser("~")
    script = os.path.basename(__file__)
    logging.info("vimrc set")
    bashrc = home + "/.bashrc"
    vimrc = home + "/.vimrc"
    added = "".join(
        ["Added by ", script, " on ", strftime("%D %T", gmtime()), "\n"]
    )

    logging.debug("checking if vim is latest and greatest")
    if 0 != subprocess.call("dpkg-query --status vim".split()):
        logging.debug("no vim found")
        if subprocess.call("sudo apt-get install -y vim".split()) != 0:
            logging.error("Could not install vim")
            return 1

    logging.debug("check if .vimrc has our additions")
    if 0 != subprocess.call(["grep", script, vimrc]):
        logging.info("our edits not found adding to vimrc")
        with open(vimrc, "a") as f:
            f.writelines(
                [
                    '" ',
                    added,
                    '" Update if file changed from outside\n',
                    "set autoread\n",
                    '" search like modern browsers\n',
                    "set incsearch\n",
                    '" show matching parentheses when you type\n',
                    "set showmatch\n",
                    '" and now use soft tabs with expandtab\n',
                    "set shiftwidth=4 tabstop=4 expandtab\n",
                    "set textwidth=80\n",
                ]
            )

    logging.debug("check if vi is our default editor")
    if 0 != subprocess.call(["grep", script, bashrc]):
        with open(bashrc, "a") as f:
            f.writelines(["# ", added, "export VISUAL=$(command -v vi)\n"])
            logging.debug("default editor is now vi")

    def installNpm(module):
        err = subprocess.call(["sudo", "npm", "install", "-g", module])
        if err != 0:
            logging.error("Could not install npm module " + module)
        else:
            logging.debug("installed " + module)
        return err

    # Syntastic automatically detects linters and connects them to default file
    # types, so we just need to install them

    # http://eslint.org/docs/user-guide/command-line-interface.html
    installNpm("eslint")
    # http://stackoverflow.com/questions/16619538/why-doesnt-syntastic-catch-json-errors
    installNpm("jsonlint")
    # use for javascript linting within html as eslint doesn't support
    # But can't figure out how to enable
    installNpm("jslint")
    # For yaml files such as .travis.yml
    installNpm("js-yaml")

    # old routines, delete when function is debugged
    if 0 != subprocess.call("sudo npm install -g jsonlint".split()):
        logging.error("Could not install jsonlint")
    else:
        logging.info("installed jsonlint")

    if 0 != subprocess.call("sudo npm install -g eslint".split()):
        logging.error("Could not install eslint")
    else:
        logging.info("installed eslint")

    if 0 != subprocess.call("sudo npm install -g jslint".split()):
        logging.error("Could not install jslint")
    else:
        logging.info("installed jslint")

    # https://github.com/scrooloose/syntastic for multiple syntax checkers
    logging.debug("check if pathogen installed")
    if not os.access(home + "/.vim/autoload/pathogen.vim", os.R_OK):
        logging.debug("trying to install pathogen")
        try:
            os.makedirs(home + "/.vim/autoload")
            os.makedirs(home + "/.vim/bundle")
        except OSError:
            pass
        # we don't use curl as it isn't available in ubuntu
        if 0 != subprocess.call("sudo apt-get -y install curl".split()):
            logging.error("could not get curl")
            return 3
        if 0 != subprocess.call(
            [
                "curl",
                "-LSso",
                home + "/.vim/autoload/pathogen.vim",
                "https://tpo.pe/pathogen.vim",
            ]
        ):
            logging.error("Could not download pathogen")
            return 4

    logging.debug("check if pathogen is in vimrc")
    if 0 != subprocess.call(["grep", "pathogen", vimrc]):
        logging.debug("installing pathogen into vimrc")
        with open(vimrc, "a") as f:
            f.writelines(
                [
                    '" ',
                    added,
                    "execute pathogen#infect()\n",
                    "syntax on\n",
                    "filetype plugin indent on\n",
                ]
            )

    def installVim(author, package):
        logging.debug("checking for installation of " + package)
        if not os.access(home + "/.vim/bundle/" + package, os.R_OK):
            logging.debug("installing " + package)
            try:
                os.chdir(home + "/.vim/bundle")
                err = subprocess.call(
                    [
                        "git",
                        "clone",
                        "https://github.com/"
                        + author
                        + "/"
                        + package
                        + ".git",
                    ]
                )
                if err != 0:
                    logging.error("could not git clone" + package)
                return err
            except OSError:
                logging.warning("~/.vim/bundle does not exist")
                return 1000

    installVim("elsr", "vim-json")

    installVim("scrooloose", "syntastic")
    logging.debug("check if syntastic set in vimrc")
    if 0 != subprocess.call(["grep", "syntastic", vimrc]):
        with open(vimrc, "a") as f:
            logging.debug("setting up syntastic in vimrc")
            f.writelines(
                [
                    '" ',
                    added,
                    "set statusline+=%#warningmsg#\n",
                    "set statusline+=%{SyntasticStatuslineFlag()}\n",
                    "set statusline+=%*\n",
                    "let g:syntastic_always_populate_loc_list = 1\n",
                    "let g:syntastic_auto_loc_list = 1\n",
                    "let g:syntastic_check_on_open = 1\n",
                    "let g:syntastic_check_on_wq = 1\n",
                    "let g:syntastic_mode_map = { 'mode' : 'passive' }\n",
                    "let g:syntastic_javascript_checkers = ['eslint', 'jshint']\n",
                    "au BufRead,BufNewFile *.json set filetype=json",
                ]
            )

    # http://ethanschoonover.com/solarized/vim-colors-solarized
    # Use vim autodetect of light and dark
    # https://github.com/Anthony25/gnome-terminal-colors-solarized
    installVim("altercation", "vim-colors-solarized")
    logging.debug("check if syntastic set in vimrc")
    if 0 != subprocess.call(["grep", "solarized", vimrc]):
        with open(vimrc, "a") as f:
            logging.debug("setting up solarized in vimrc")
            f.writelines(
                [
                    '" ',
                    added,
                    "syntax enable\n",
                    "colorscheme solarized\n",
                    "if has('gui_running')\n",
                    "  set background=light\n",
                    "else\n",
                    "  set background=dark\n",
                    "endif\n",
                ]
            )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
