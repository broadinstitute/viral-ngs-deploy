set -e

if [ "$TEST_EASY_INSTALL" == "true" ]; then
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ "$TEST_DOCKER" == "true" ]; then
    rm ./docker/easy-deploy-script # remove symlink if present
    cp -r ./easy-deploy-script ./docker/
    docker build --rm ./docker/
fi