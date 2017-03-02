FROM ubuntu:16.04

MAINTAINER Chris Tomkins-Tinch <tomkinsc@broadinstitute.org>

# to build:
#   docker build --rm .
# to run:
#   Download licensed copies of GATK and Novoalign to the host machine (for Linux-64)
#   export GATK_PATH=/path/to/gatk/
#   export NOVOALIGN_PATH=/path/to/novoalign/
#   docker run --rm -v $GATK_PATH:/gatk -v $NOVOALIGN_PATH:/novoalign -v /path/to/dir/on/host:/user-data -t -i <image_ID> "<command>.py subcommand"
# if you receive a "no space on device" error:
#   docker kill $(docker ps -a -q)
#   docker rm $(docker ps -a -q)
#   docker rmi $(docker images -q)
#   docker volume rm $(docker volume ls -qf dangling=true)

ARG VIRAL_NGS_VERSION

# Silence some warnings about Readline. Checkout more over here:
# https://github.com/phusion/baseimage-docker/issues/58
ENV DEBIAN_FRONTEND noninteractive

# System packages 
RUN apt-get update && \
apt-get install -y curl bzip2 build-essential python wget less nano libterm-readline-gnu-perl &&\
apt-get upgrade -y

# Set the locale
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# add a new user
ENV DOCKER_USER viral-ngs-user
RUN useradd -ms /bin/bash $DOCKER_USER
USER $DOCKER_USER
WORKDIR /home/$DOCKER_USER

# shared volumes to make external GATK available within the container
VOLUME ["/gatk"]
ENV GATK_PATH /gatk

# shared volumes to make external Novoalign available within the container
VOLUME ["/novoalign"]
ENV NOVOALIGN_PATH /novoalign

# shared volumes to make external Novoalign available within the container
VOLUME ["/user-data"]
ENV VIRAL_NGS_DOCKER_DATA_PATH /user-data

RUN ln -s /user-data /home/$DOCKER_USER/data

# download and use the viral-ngs easy deploy script to install viral-ngs
#RUN curl -LO https://raw.githubusercontent.com/broadinstitute/viral-ngs-deploy/master/easy-deploy-script/easy-deploy-viral-ngs.sh
USER root
ADD ./easy-deploy-script/easy-deploy-viral-ngs.sh /home/$DOCKER_USER/easy-deploy-viral-ngs.sh
RUN chmod +x ./easy-deploy-viral-ngs.sh && \
    chown $DOCKER_USER:$DOCKER_USER ./easy-deploy-viral-ngs.sh
USER $DOCKER_USER
ENV VIRAL_NGS_VERSION $VIRAL_NGS_VERSION

RUN echo "Running easy install with viral-ngs version $VIRAL_NGS_VERSION"
RUN bash -c '$(if [ "$VIRAL_NGS_VERSION" == "" ]; then echo "./easy-deploy-viral-ngs.sh setup"; else echo "./easy-deploy-viral-ngs.sh setup --viral-ngs-version $VIRAL_NGS_VERSION" ; fi)'

# add a wrapper script to load the viral-ngs environment via the easy-deploy script
# and then run any commands desired
USER root
ADD ./env_wrapper.sh /home/$DOCKER_USER/env_wrapper.sh
RUN chmod +x ./env_wrapper.sh && chown $DOCKER_USER:$DOCKER_USER ./env_wrapper.sh
USER $DOCKER_USER

ENV DEBIAN_FRONTEND teletype

ENTRYPOINT ["./env_wrapper.sh"]
