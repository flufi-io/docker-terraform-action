FROM ubuntu:latest

ARG TERRAFORM_VERSION

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    sudo

# Install Homebrew
RUN sudo -u linuxbrew /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Set up Homebrew environment
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.bashrc \
    && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> $HOME/.profile \
    && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install packages with Homebrew
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
