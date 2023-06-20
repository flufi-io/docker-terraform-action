FROM ubuntu:latest

ARG TERRAFORM_VERSION

# Install prerequisites
RUN apt-get update && apt-get install -y -q --allow-unauthenticated \
    curl \
    git \
    sudo \
    build-essential

# Create linuxbrew user and directory
RUN useradd -m -s /bin/shellenv linuxbrew && \
    usermod -aG sudo linuxbrew && \
    mkdir -p /home/linuxbrew/.linuxbrew && \
    chown -R linuxbrew: /home/linuxbrew/.linuxbrew

# Switch to linuxbrew user
USER linuxbrew

# Install Homebrew
RUN curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash -s -- --disable-analytics --install-dir=/home/linuxbrew/.linuxbrew

# Set up Homebrew environment
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bashrc \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.profile \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install packages with Homebrew
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN brew install pre-commit \
    && brew install git \
    && brew install yq \
    && brew install jq \
    && brew install go \
    && brew install terraform-docs \
    && brew install tfsec \
    && brew install checkov \
    && brew install tflint

# Install tfenv and set the specified Terraform version
RUN brew install tfenv \
    && tfenv install ${TERRAFORM_VERSION} \
    && tfenv use ${TERRAFORM_VERSION}

USER root
CMD ["/bin/bash"]
