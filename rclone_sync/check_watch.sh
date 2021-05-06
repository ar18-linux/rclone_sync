#!/bin/zsh

# get pipe input from a watch, when changed get directory name,
# check if its in sync pairs, if so read respective line from it
# and check if line is in temp file, if not write it and trigger run
# from the main script.