set -e

if [ "$TEST_EASY_INSTALL" == "true" ]; then
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ "$TEST_DOCKER" == "true" ]; then
    ln -s ./easy-deploy-script ./docker/easy-deploy-script
    docker build --rm ./docker/
fi