FROM ubuntu:latest

ARG TERRAFORM_VERSION





# Install prerequisites
RUN apt-get update && apt-get install -y  -q --allow-unauthenticated \
    curl \
    git \
    sudo \
    build-essential
RUN useradd -m -s /bin/shellenv linuxbrew && \
    usermod -aG sudo linuxbrew &&  \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew: /home/linuxbrew/.linuxbrew

USER linuxbrew
# Install Homebrew
RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set up Homebrew environment
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bashrc \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.profile \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

RUN chown -R $CONTAINER_USER: /home/linuxbrew/.linuxbrew
# Install packages with Homebrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN brew install pre-commit
RUN brew install git
RUN brew install yq
RUN brew install jq
RUN brew install go
RUN brew install terraform-docs
RUN brew install tfsec
RUN brew install checkov
RUN brew install tflint

# Install tfenv and set the specified Terraform version
RUN brew install tfenv
RUN tfenv install ${TERRAFORM_VERSION}
RUN tfenv use ${TERRAFORM_VERSION}

CMD ["/bin/bash"]
