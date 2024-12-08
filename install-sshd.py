#!/usr/bin/env python

"""Automatic installation of ssh daemon.

@package install-sshd
@author Rich Tong
"""

# http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python

import argparse

# Need expanduser to interpret the ~ in filenames
import logging
import os
import subprocess
import sys

# http://stackoverflow.com/questions/415511/how-to-get-current-time-in-python
from datetime import datetime
from time import gmtime, strftime


def main(args):
    """Parse command line arguments and run it for a single file.

    @param args command line
    """
    #    logging.basicConfig(level=logging.DEBUG)
    #    logging.debug("Main arguments: %s", args)
    if "linux" not in sys.platform:
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
    script = os.path.basename(__file__)
    sshdConfig = os.path.abspath("/etc/ssh/sshd_config")
    added = "".join(
        ["Added by ", script, " on ", strftime("%D %T", gmtime()), "\n"],
    )

    logging.debug("Check is sshd is running")
    if 0 != subprocess.call("sudo service sshd status".split()):
        logging.debug("no sshd found so install it")
        if subprocess.call("sudo apt-get install -y openssh-server".split()) != 0:
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
                ],
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
    if not open(service).read().find("Added by " + scriptname):
        with open(service, "a+") as f:
            f.write(
                f"Added by {scriptname} on {datetime.now()!s}",
            )
            f.write(
                """<service-group>
<name replace-wildcards="yes">%h</name>
<service>
<type>_ssh._tcp</type>
<port>22</port>
</service>
</service-group>
""",
            )

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
