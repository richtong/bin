#!/usr/bin/env python2.7

"""Install vim.

@package install-vim

Automatic installation of vim and it"s packages
Rich learning to write python
"""

import argparse

# Need expanduser to interpret the ~ in filenames
import logging
import os
import subprocess
import sys
from pathlib import Path
from time import gmtime, strftime


def main(args: str) -> None:  # noqa: C901 PLR0912 PLR0915
    """Parse command line arguments and run it for a single file.

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
    home = Path.name("~")
    script = Path.name(__file__)
    logging.info("vimrc set")
    bashrc = home + "/.bashrc"
    vimrc = home + "/.vimrc"
    added = "".join(
        ["Added by ", script, " on ", strftime("%D %T", gmtime()), "\n"],
    )

    logging.debug("checking if vim is latest and greatest")
    if 0 != subprocess.call("dpkg-query --status vim".split()):  # noqa: S603
        logging.debug("no vim found")
        if subprocess.call("sudo apt-get install -y vim".split()) != 0:  # noqa: S603
            logging.error("Could not install vim")
            return 1

    logging.debug("check if .vimrc has our additions")
    if 0 != subprocess.call(["grep", script, vimrc]):  # noqa: S603,S607
        logging.info("our edits not found adding to vimrc")
        with Path.open(vimrc, "a") as f:
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
                ],
            )

    logging.debug("check if vi is our default editor")
    if 0 != subprocess.call(["grep", script, bashrc]):  # noqa: S603,S607
        with Path.open(bashrc, "a") as f:
            f.writelines(["# ", added, "export VISUAL=$(command -v vi)\n"])
            logging.debug("default editor is now vi")

    def install_npm(module: str) -> int:
        err = subprocess.call(["sudo", "npm", "install", "-g", module])  # noqa: S603,S607
        if err != 0:
            logging.error("Could not install npm module " + module)
        else:
            logging.debug("installed " + module)
        return err

    # Syntastic automatically detects linters and connects them to default file
    # types, so we just need to install them

    # http://eslint.org/docs/user-guide/command-line-interface.html
    install_npm("eslint")
    # http://stackoverflow.com/questions/16619538/why-doesnt-syntastic-catch-json-errors
    install_npm("jsonlint")
    # use for javascript linting within html as eslint doesn't support
    # But can't figure out how to enable
    install_npm("jslint")
    # For yaml files such as .travis.yml
    install_npm("js-yaml")

    # old routines, delete when function is debugged
    if 0 != subprocess.call("sudo npm install -g jsonlint".split()):  # noqa: S603
        logging.error("Could not install jsonlint")
    else:
        logging.info("installed jsonlint")

    if 0 != subprocess.call("sudo npm install -g eslint".split()):  # noqa: S603
        logging.error("Could not install eslint")
    else:
        logging.info("installed eslint")

    if 0 != subprocess.call("sudo npm install -g jslint".split()):  # noqa: S603
        logging.error("Could not install jslint")
    else:
        logging.info("installed jslint")

    # https://github.com/scrooloose/syntastic for multiple syntax checkers
    logging.debug("check if pathogen installed")
    if not os.access(home + "/.vim/autoload/pathogen.vim", os.R_OK):
        logging.debug("trying to install pathogen")
        try:
            Path.mkdir(home + "/.vim/autoload", parents=True)
            Path.mkdir(home + "/.vim/bundle", parents=True)
        except OSError:
            pass
        # we don't use curl as it isn't available in ubuntu
        if 0 != subprocess.call("sudo apt-get -y install curl".split()):  # noqa: S603
            logging.error("could not get curl")
            return 3
        if 0 != subprocess.call(  # noqa: S603
            [  # noqa: S607
                "curl",
                "-LSso",
                home + "/.vim/autoload/pathogen.vim",
                "https://tpo.pe/pathogen.vim",
            ],
        ):
            logging.error("Could not download pathogen")
            return 4

    logging.debug("check if pathogen is in vimrc")
    if 0 != subprocess.call(["grep", "pathogen", vimrc]):  # noqa: S603,S607
        logging.debug("installing pathogen into vimrc")
        with Path.open(vimrc, "a") as f:
            f.writelines(
                [
                    '" ',
                    added,
                    "execute pathogen#infect()\n",
                    "syntax on\n",
                    "filetype plugin indent on\n",
                ],
            )

    def install_vim(author: str, package: str) -> None:
        logging.debug("checking for installation of " + package)
        if not os.access(home + "/.vim/bundle/" + package, os.R_OK):
            logging.debug("installing " + package)
            try:
                os.chdir(home + "/.vim/bundle")
                err = subprocess.call(  # noqa: S603
                    [  # noqa:S607
                        "git",
                        "clone",
                        "https://github.com/" + author + "/" + package + ".git",
                    ],
                )
                if err != 0:
                    logging.error("could not git clone" + package)
                return err
            except OSError:
                logging.warning("~/.vim/bundle does not exist")
                return 1000

    install_vim("elsr", "vim-json")

    install_vim("scrooloose", "syntastic")
    logging.debug("check if syntastic set in vimrc")
    if 0 != subprocess.call(["grep", "syntastic", vimrc]):  # noqa: S603,S607
        with Path.open(vimrc, "a") as f:
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
                    "let g:syntastic_javascript_checkers=['eslint']\n",
                    "au BufRead,BufNewFile *.json set filetype=json",
                ],
            )

    # http://ethanschoonover.com/solarized/vim-colors-solarized
    # Use vim autodetect of light and dark
    # https://github.com/Anthony25/gnome-terminal-colors-solarized
    install_vim("altercation", "vim-colors-solarized")
    logging.debug("check if syntastic set in vimrc")
    if 0 != subprocess.call(["grep", "solarized", vimrc]):  # noqa: S603,S607
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
            ],
        )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
