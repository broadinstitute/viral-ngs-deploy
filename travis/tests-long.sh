
# if this build has been kicked off via API
# and a version string has been passed

if [ ! -z "$PKG_VERSION" ]; then
    if [ ! -z "$TEST_EASY_INSTALL" ]; then
        # render recipe template to recipe
        ./conda-recipe/render-recipe.py
        conda build ./conda-recipe/viral-ngs/
        ./easy-deploy-script/easy-deploy-viral-ngs.sh setup --use-local
    fi
fi