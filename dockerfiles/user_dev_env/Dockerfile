################################################################################
ARG BASE_LAYER
FROM ${BASE_LAYER}

################################################################################

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install \
    ccache \
    fonts-font-awesome \
    fonts-ubuntu \
    gnupg2 \
    jq \
    libcapnp-dev \
    manpages-dev \
    ninja-build \
    silversearcher-ag \
    stow \
    sudo \
    wmctrl \
    zsh \
    && rm -rf /var/lib/apt/lists/*

ADD /sudoers.txt /etc/sudoers
RUN chmod 440 /etc/sudoers

ARG GROUP_ID
ARG USER_ID
ARG USER_NAME
ARG USER_SHELL

RUN useradd -l -d /home/${USER_NAME} -s ${USER_SHELL} -u ${USER_ID} -G sudo ${USER_NAME}

USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
