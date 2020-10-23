FROM python:3.8-buster

ARG USERNAME=tf
# On Linux, replace with your actual UID, GID if not the default 1000
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /home/$USERNAME/.vscode-server /home/$USERNAME/.vscode-server-insiders \
    && chown ${USER_UID}:${USER_GID} /home/$USERNAME/.vscode-server*

# ********************************************************
# * Anything else you want to do like clean up goes here *
# ********************************************************

RUN apt update && apt install zip groff less -y && rm -rf /var/lib/apt/lists/*
RUN curl -L https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_linux_amd64.zip -o /tmp/tf.zip; unzip /tmp/tf.zip -d /usr/local/bin/; rm /tmp/tf.zip

# install AWS CLI (requires groff, less, glibc)
RUN curl -L https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/aws.zip; unzip /tmp/aws.zip; ./aws/install; rm /tmp/aws.zip

# change the username
USER $USERNAME