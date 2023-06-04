FROM ubuntu:latest

ARG TERRAFORM_VERSION

# Install prerequisites
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential

# Set up Linuxbrew environment
ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
ENV MANPATH="/home/linuxbrew/.linuxbrew/share/man:${MANPATH}"
ENV INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH}"

# Install Linuxbrew
RUN apt-get install -y locales && \
    locale-gen en_US.UTF-8 && \
    echo 'export LC_ALL=en_US.UTF-8' >> $HOME/.bashrc && \
    echo 'export LANG=en_US.UTF-8' >> $HOME/.bashrc && \
    echo 'export LANGUAGE=en_US.UTF-8' >> $HOME/.bashrc && \
    useradd -m -s /bin/bash linuxbrew && \
    usermod -aG sudo linuxbrew && \
    echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers && \
    su - linuxbrew -c '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' && \
    echo 'eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >> /home/linuxbrew/.bashrc && \
    echo 'export PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"' >> /home/linuxbrew/.bashrc

# Install packages with Linuxbrew
RUN su - linuxbrew -c 'brew install pre-commit'
RUN su - linuxbrew -c 'brew install git'
RUN su - linuxbrew -c 'brew install yq'
RUN su - linuxbrew -c 'brew install jq'
RUN su - linuxbrew -c 'brew install go'
RUN su - linuxbrew -c 'brew install terraform-docs'
RUN su - linuxbrew -c 'brew install tfsec'
RUN su - linuxbrew -c 'brew install checkov'
RUN su - linuxbrew -c 'brew install tflint'

# Install tfenv and set the specified Terraform version
RUN su - linuxbrew -c 'brew install tfenv'
RUN su - linuxbrew -c 'tfenv install ${TERRAFORM_VERSION}'
RUN su - linuxbrew -c 'tfenv use ${TERRAFORM_VERSION}'

CMD ["/bin/bash"]
