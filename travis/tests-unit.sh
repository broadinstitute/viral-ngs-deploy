set -e

if [ "$TEST_EASY_INSTALL" == "true" ]; then
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ "$TEST_DOCKER" == "true" ]; then
    # remove symlink if present
    rm ./docker/easy-deploy-script 
    # copy in easy deploy script since Docker can't add things
    # from higher in the filesystem hierarchy
    cp -r ./easy-deploy-script ./docker/ 
    docker build --rm ./docker/
fi