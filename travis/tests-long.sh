#!/bin/bash

set -e

# if this build has been kicked off via API
# and a version string has been passed

echo ""
echo "UPSTREAM_BRANCH: $UPSTREAM_BRANCH"
echo "UPSTREAM_TAG: $UPSTREAM_TAG"
echo ""

if [ ! -z "$PKG_VERSION" ]; then
    if [ ! -z "$TEST_EASY_INSTALL" ]; then
        # render recipe template to recipe
        ./conda-recipe/render-recipe.py
        # build the rendered recipe
        conda build ./conda-recipe/viral-ngs/
        # try to easy-deploy the built conda package, and if it succeeds update bioconda
        ./easy-deploy-script/easy-deploy-viral-ngs.sh setup --use-local && ./travis/update-bioconda.sh
    fi
fi