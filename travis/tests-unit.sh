set -e

if [ ! -z "$TEST_EASY_INSTALL" ]; then
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ ! -z "$TEST_DOCKER" ]; then
    docker build --rm ./docker/
fi