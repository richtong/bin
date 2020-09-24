#!/usr/bin/env python

"""@package install-sshd
    @author Rich Tong
    Automatic installation of ssh daemon
"""

# http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python
from __future__ import print_function

import sys

import os
import shutil

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

# http://stackoverflow.com/questions/415511/how-to-get-current-time-in-python
from datetime import datetime


def main(args):
    """Parse command line arguments and run it for a single file

    @param args command line
    """

    #    logging.basicConfig(level=logging.DEBUG)
    #    logging.debug("Main arguments: %s", args)
    if not "linux" in sys.platform:
        print("only runs on linux", file=sys.stderr)
        sys.exit(os.EX_CONFIG)

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
    sshdConfig = os.path.abspath("/etc/ssh/sshd_config")
    added = "".join(
        ["Added by ", script, " on ", strftime("%D %T", gmtime()), "\n"]
    )

    logging.debug("Check is sshd is running")
    if 0 != subprocess.call("sudo service sshd status".split()):
        logging.debug("no sshd found so install it")
        if (
            subprocess.call("sudo apt-get install -y openssh-server".split())
            != 0
        ):
            logging.error("Could not install openssh-server")
            return 1

    logging.debug("check if sshd_config has our additions")
    if 0 != subprocess.call(["grep", added, sshdConfig]):
        logging.info("our edits not found adding")
        with open(sshdConfig, "a") as f:
            f.writelines(
                [
                    "#",
                    added,
                    # Currently no lines to add
                ]
            )

    logging.debug("start sshd server")
    if 0 != subprocess.call("sudo service ssh restart".split()):
        logging.debug("could not start ssh")

    # http://superuser.com/questions/108414/zeroconf-ssh-advertising-utility
    # so you can just ssh hostname without needed .local
    logging.debug("install avahi ssh advertising")
    service = "/etc/avahi/ssh.service"
    dir = os.path.dirname(service)
    if not os.path.exists(dir):
        subprocess.call(["sudo", "mkdir", "-p", dir])
    scriptname = os.path.basename(__file__)
    if not open(service, "r").read().find("Added by " + scriptname):
        with open(service, "a+") as f:
            f.write(
                "Added by {} on {}".format(scriptname, str(datetime.now()))
            )
            f.write(
                """<service-group>
<name replace-wildcards="yes">%h</name>
<service>
<type>_ssh._tcp</type>
<port>22</port>
</service>
</service-group>
"""
            )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
