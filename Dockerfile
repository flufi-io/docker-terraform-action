# Use a build stage to build the Go applications
FROM golang:alpine AS go-builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    git \
    build-base \
    bash

# Install terraform-docs and tfsec
RUN go install github.com/terraform-docs/terraform-docs@latest && \
    go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Install tfupdate
RUN go install github.com/minamijoyo/tfupdate@latest

# Install terrascan
RUN git clone https://github.com/tenable/terrascan.git && \
    cd terrascan && \
    make build

# Remove build dependencies
RUN apk del build-base

# Use a build stage for Python dependencies
FROM python:3.9-slim-buster AS python-builder

# Upgrade pip and setuptools, and install checkov and pre-commit
RUN pip install --upgrade pip setuptools && \
    pip install checkov pre-commit

# Start a new stage for the runtime
FROM alpine:latest

# Install bash and git
RUN apk add --no-cache bash git

# Install Python, pip, and build dependencies
RUN apk add --no-cache python3 py3-pip build-base

# Install pre-commit
RUN pip install pre-commit

# Copy the Go binaries from the go-builder stage
COPY --from=go-builder /go/bin/terraform-docs /usr/local/bin/
COPY --from=go-builder /go/bin/tfsec /usr/local/bin/
COPY --from=go-builder /go/bin/tfupdate /usr/local/bin/
COPY --from=go-builder /go/terrascan/bin/terrascan /usr/local/bin/

# Copy Python dependencies from the python-builder stage
COPY --from=python-builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    curl \
    jq \
    unzip

# Install tflint
RUN TFLINT_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | jq -r .tag_name) && \
    wget https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip && \
    unzip tflint_linux_amd64.zip && \
    install tflint /usr/local/bin && \
    rm tflint_linux_amd64.zip

# Fetch the latest version of Terraform
RUN TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version') && \
    curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Clean up
RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

CMD ["/bin/bash"]
