#!/bin/bash

# this file should be sourced in .travis.yml

# this installs "hub", the command-line interface to GitHub
if [ -z "$CACHE_DIR/hub-linux-amd64-2.2.5/bin/hub" ]; then
    wget https://github.com/github/hub/releases/download/v2.2.5/hub-linux-amd64-2.2.5.tgz
    tar -xvf hub-linux-amd64-2.2.5.tgz
    mv ./hub-linux-amd64-2.2.5 $CACHE_DIR/opt/
fi

alias git=$CACHE_DIR/opt/hub-linux-amd64-2.2.5/bin/hub