#!/usr/bin/env python
"""Check for AWS Credentials."""

import sys
import os

from surroundio.utility.awstools import getAwsProfile  # type:ignore


def findPymodDir(start):
    """Find standard lib location logic."""
    path = os.path.realpath(start)
    while path != "/":
        candidatePymod = os.path.realpath("%s/common/pymod" % path)
        if os.path.exists(candidatePymod + "/surroundio/utility"):
            return candidatePymod
        candidatePymod = os.path.realpath("%s/pymod" % path)
        if os.path.exists(candidatePymod + "/surroundio/utility"):
            return candidatePymod
        path = os.path.realpath("%s/.." % path)

    raise Exception("Can't find the pymod dir; something is wrong")


# Find pymod so we can import the common utility code.
scriptDir = os.path.dirname(os.path.realpath(sys.argv[0]))
pymodDir = findPymodDir(scriptDir)
sys.path.append(pymodDir)

# Surround imports


OKGREEN = "\033[92m"
OKBLUE = "\033[94m"
FAILRED = "\033[91m"
ENDC = "\033[0m"
BOLD = "\033[1m"

yourAwsProfile = getAwsProfile()
print(BOLD + "Your AWS Profile:\n==============" + ENDC)

print(yourAwsProfile)

region = "region" in yourAwsProfile
output = "output" in yourAwsProfile
aws_secret_access_key = "aws_secret_access_key" in yourAwsProfile
aws_access_key_id = "aws_access_key_id" in yourAwsProfile

if region and output and aws_access_key_id and aws_secret_access_key:
    print(OKGREEN + BOLD + "Your profile looks complete!!" + ENDC)
    sys.exit(0)

print(
    BOLD
    + FAILRED
    + "You should examine your ~/.aws/config"
    + "~/.aws/credentials, or"
    + ENDC
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
