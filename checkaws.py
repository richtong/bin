#!/usr/bin/env python
"""Check for AWS Credentials."""

import os
import sys
from pathlib import Path

from surroundio.utility.awstools import getAwsProfile  # type:ignore


def find_pymod_dir(start: str) -> None:
    """Find standard lib location logic."""
    path = os.path.realpath(start)
    while path != "/":
        candidate_pymod = os.path.realpath(f"{path}/common/pymod")
        if Path.exists(candidate_pymod + "/surroundio/utility"):
            return candidate_pymod
        candidate_pymod = os.path.realpath(f"{path}/pymod")
        if Path.exists(candidate_pymod + "/surroundio/utility"):
            return candidate_pymod
        path = os.path.realpath("{path}/..")
    msg = "find the pymod dir; something is wrong"
    raise Exception(msg)


# Find pymod so we can import the common utility code.
script_dir = Path.parent(os.path.realpath(sys.argv[0]))
pymod_dir = find_pymod_dir(script_dir)
sys.path.append(pymod_dir)

# Surround imports


OKGREEN = "\033[92m"
OKBLUE = "\033[94m"
FAILRED = "\033[91m"
ENDC = "\033[0m"
BOLD = "\033[1m"

your_aws_profile = getAwsProfile()
print(BOLD + "Your AWS Profile:\n==============" + ENDC)

print(your_aws_profile)

region = "region" in your_aws_profile
output = "output" in your_aws_profile
aws_secret_access_key = "aws_secret_access_key" in your_aws_profile
aws_access_key_id = "aws_access_key_id" in your_aws_profile

if region and output and aws_access_key_id and aws_secret_access_key:
    print(OKGREEN + BOLD + "Your profile looks complete!!" + ENDC)
    sys.exit(0)

print(
    BOLD
    + FAILRED
    + "You should examine your ~/.aws/config"
    + "~/.aws/credentials, or"
    + ENDC,
)
print(BOLD + FAILRED + "  your AWS_CONFIG_FILE env var." + ENDC)
if not region:
    print(FAILRED + "You are missing a region setting." + ENDC)

if not output:
    print(FAILRED + "You are missing the output setting." + ENDC)

if not aws_secret_access_key:
    print(FAILRED + "You are missing your aws_secret_access_key." + ENDC)

if not aws_access_key_id:
    print(FAILRED + "You are missing your aws_access_key_id." + ENDC)
