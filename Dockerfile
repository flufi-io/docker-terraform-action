# Use a build stage for Go applications
FROM golang:alpine AS go-builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    git \
    build-base \
    bash

# Install terraform-docs, tfsec, tfupdate, and terrascan
RUN go install github.com/terraform-docs/terraform-docs@latest \
    github.com/aquasecurity/tfsec/cmd/tfsec@latest \
    github.com/minamijoyo/tfupdate@latest \
    github.com/tenable/terrascan@latest

# Use a build stage for Python dependencies
FROM python:3.9-alpine AS python-builder

# Install build dependencies
RUN apk add --no-cache build-base python3-dev

# Upgrade pip and setuptools, and install checkov and pre-commit
RUN pip install --upgrade pip setuptools \
    && pip install checkov pre-commit

# Start a new stage for the runtime
FROM alpine:latest

# Install bash, git, Python, pip, curl, jq, unzip, and runtime dependencies
RUN apk add --no-cache bash git python3 py3-pip curl jq unzip

# Copy the Go binaries from the go-builder stage
COPY --from=go-builder /go/bin/ /usr/local/bin/

# Copy Python dependencies from the python-builder stage
COPY --from=python-builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/

# Install tflint
RUN TFLINT_VERSION=$(curl -s https://api.github.com/repos/terraform-linters/tflint/releases/latest | jq -r .tag_name) \
    && wget https://github.com/terraform-linters/tflint/releases/download/${TFLINT_VERSION}/tflint_linux_amd64.zip \
    && unzip tflint_linux_amd64.zip \
    && install tflint /usr/local/bin \
    && rm tflint_linux_amd64.zip

# Fetch the latest version of Terraform
RUN TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version') \
    && curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin/ \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

# Set the working directory
WORKDIR /app

# Copy the application files to the container
COPY . .

# Run the application
CMD ["bash"]
