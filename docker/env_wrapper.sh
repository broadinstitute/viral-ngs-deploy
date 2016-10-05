#!/bin/bash

# This script sets up the viral-ngs environment by sourcing the
# easy-deploy script, then running whatever is passed in

export SKIP_VERSION_CHECK=true

source ./easy-deploy-viral-ngs.sh load

$@