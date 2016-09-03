set -e

if [ "$TEST_EASY_INSTALL" == "true" ]; then
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ "$TEST_ANSIBLE" == "true" ]; then
    ansible-playbook ./ansible/viral-ngs-playbook.yml -i "localhost," --connection=local --sudo
fi

if [ "$TEST_DOCKER" == "true" ]; then
    # tar contents to dereference symlinks
    cd ./docker
    tar -czh . | docker build --rm -
fi

