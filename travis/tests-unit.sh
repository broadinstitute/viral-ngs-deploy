#!/bin/bash

set -e -x

echo ""
echo "UPSTREAM_BRANCH: $UPSTREAM_BRANCH"
echo "UPSTREAM_TAG: $UPSTREAM_TAG"
echo ""

if [ "$TEST_EASY_INSTALL" == "true" ]; then
    echo "Checking easy install script..."
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup
fi

if [ "$TEST_EASY_INSTALL" == "git" ]; then
    echo "Checking git install script..."
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh /tmp/easy-deploy-viral-ngs.sh
    /tmp/easy-deploy-viral-ngs.sh setup-git
fi

if [ "$TEST_EASY_INSTALL" == "long_prefix" ]; then
    echo "Checking easy install script with long path prefix..."
    echo "See: https://github.com/conda/conda-build/pull/877"
    mkdir -p /tmp/this/is/a/long/path/prefix/greater/than/eighty/characters/in/lenth/to/test/conda/prefix/length/limits/
    cp ./easy-deploy-script/easy-deploy-viral-ngs.sh "/tmp/this/is/a/long/path/prefix/greater/than/eighty/characters/in/lenth/to/test/conda/prefix/length/limits/easy-deploy-viral-ngs.sh"
    
    # check the exit code of the setup script. Until the build prefix issue is fixed, 
    # our script will check the path prefix and we can condsider exit code 80 to be a successful test
    set +e # disable exit-on-error
    /tmp/this/is/a/long/path/prefix/greater/than/eighty/characters/in/lenth/to/test/conda/prefix/length/limits/easy-deploy-viral-ngs.sh setup
    rc="$?"
    if [[ "$rc" == "80" ]]; then true; else exit $(($rc + 0)); fi
    set -e # re-enable exit-on-error
fi

if [ "$TEST_ANSIBLE" == "true" ]; then
    ansible-playbook ./ansible/viral-ngs-playbook.yml -i "localhost," --connection=local --sudo
fi

if [ "$TEST_DOCKER" == "true" ]; then
    # tar contents to dereference symlinks
    cd ./docker

    if [ -z "$UPSTREAM_TAG" ]; then
        # build the docker image, and try to run it
        tar -czh . | docker build --rm - | tee >(grep "Successfully built" | perl -lape 's/^Successfully built ([a-f0-9]{12})$/$1/g' > build_id) | grep ".*" && build_image=$(head -n 1 build_id) && rm build_id

        if [[ ! -z $build_image ]]; then
            echo "build_image: $build_image"
            docker run --rm $build_image illumina.py
        else
            echo "Docker build failed."
        fi
    # if this was triggered by the upstream repo, build, tag, and push to Docker Hub
    else
        export REPO=broadinstitute/viral-ngs
        export TAG=$(if [ "$UPSTREAM_TAG" == "master" ]; then echo "latest"; else echo "$UPSTREAM_TAG" ; fi)
        export VIRAL_NGS_VERSION=$(echo "$UPSTREAM_TAG" | perl -lape 's/^v(.*)/$1/g') # strip 'v' prefix
        tar -czh . | docker build --build-arg VIRAL_NGS_VERSION=$VIRAL_NGS_VERSION --rm -t "$REPO:$VIRAL_NGS_VERSION" - | tee >(grep "Successfully built" | perl -lape 's/^Successfully built ([a-f0-9]{12})$/$1/g' > build_id) | grep ".*" && build_image=$(head -n 1 build_id) && rm build_id

        if [[ ! -z $build_image ]]; then
            echo "build_image: $build_image"
            docker run --rm $build_image illumina.py && docker login -u "$DOCKER_USER" -p "$DOCKER_PASS" && docker push "$REPO:$VIRAL_NGS_VERSION"
        else
            echo "Docker build failed."
        fi
    fi
fi
