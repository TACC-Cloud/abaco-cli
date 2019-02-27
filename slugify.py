#!/usr/bin/env python
"""
    Usage: slugify.py "string_to_convert"
    Convert strings potentially containing special characters to a slugified
    ASCII version safe for directory names, git repositories, and Abaco.

    Example:
        slugify.py "cr@zy $tr1ng t0 (onver!"
"""

from __future__ import print_function
import argparse
import re

parser = argparse.ArgumentParser(
            description="Copy files to/from/between remote systems")

parser.add_argument(
    "unsafe_string",
    action="store",
    help="String to convert into a safe slug")

def slugify(unsafe_string):
    temp_string = re.sub('[^A-Za-z0-9 _-]+', '', unsafe_string)
    temp_string = re.sub(' ', '_', temp_string)
    return temp_string.lower()

if __name__ == "__main__":
    args = parser.parse_args()
    unsafe_string = args.unsafe_string
    safe_string = slugify(unsafe_string)
    print(safe_string)
