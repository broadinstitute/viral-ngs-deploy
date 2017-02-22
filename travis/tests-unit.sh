set -e

echo ""
echo "UPSTREAM_BRANCH: $UPSTREAM_BRANCH"
echo "UPSTREAM_TAG: $UPSTREAM_TAG"
echo ""

if [ "$TEST_EASY_INSTALL" == "true" ]; then
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ "$TEST_ANSIBLE" == "true" ]; then
    ansible-playbook ./ansible/viral-ngs-playbook.yml -i "localhost," --connection=local --sudo
fi

if [ "$TEST_DOCKER" == "true" ]; then
    export REPO=broadinstitute/viral-ngs
    export TAG=$(if [ "$UPSTREAM_TAG" == "master" ]; then echo "latest"; else echo "$UPSTREAM_TAG" ; fi)
    # tar contents to dereference symlinks
    cd ./docker

    if [ -z "$UPSTREAM_TAG" ]; then
        # build the docker image, and try to run it
        tar -czh . | docker build --rm -q - | xargs -I{} docker run --rm {} illumina.py
    # if this was triggered by the upstream repo, build, tag, and push to Docker Hub
    else
        docker login -e "$DOCKER_EMAIL" -u "$DOCKER_USER" -p "$DOCKER_PASS"
        export VIRAL_NGS_VERSION=$(echo "$UPSTREAM_TAG" | perl -lape 's/^v(.*)/$1/g') # strip 'v' prefix
        tar -czh . | docker build --build-arg VIRAL_NGS_VERSION=$VIRAL_NGS_VERSION --rm -t "$REPO:$TAG" -q - | xargs -I{} docker run --rm {} illumina.py && docker push "$REPO:$TAG"
    fi
fi

