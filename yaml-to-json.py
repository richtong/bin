#!/usr/bin/env python
"""Convert yaml at stdin to json on stdout.

@package install-sshd
@author Rich Tong
"""

# http://stackoverflow.com/questions/5574702/how-to-print-to-stderr-in-python

import argparse
import json

# Need expanduser to interpret the ~ in filenames
import logging
import sys

import pyyaml as yaml  # type: ignore


def main(args: str) -> None:
    """Run the dumper.

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
