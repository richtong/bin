#!/usr/bin/env python

"""@package install-sshd
    @author Rich Tong
    Convert yaml at stdin to json on stdout
"""

# http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python
from __future__ import print_function

import sys
import yaml
import json

# Need expanduser to interpret the ~ in filenames
import logging
import argparse

# http://bugs.python.org/issue23223
try:
    import subprocess32 as subprocess
except ImportError:
    import subprocess


def main(args):
    """Runs the dumper

    @param args command line
    """

    #    logging.basicConfig(level=logging.DEBUG)
    logging.debug("Main arguments: %s", args)

    # https://docs.python.org/2/howto/argparse.html
    parser = argparse.ArgumentParser(description="YAML to JSON")
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

    json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)


if __name__ == "__main__":
    sys.exit(main(sys.argv))
