# Use a build stage to build the Go applications
FROM golang:alpine AS builder

# Install build dependencies
RUN apk update && apk add --no-cache \
    git \
    build-base

# Install terraform-docs and tfsec
RUN go install github.com/terraform-docs/terraform-docs@v0.16.0 && \
    go install github.com/aquasecurity/tfsec/cmd/tfsec@latest

# Install tfupdate
RUN go install github.com/minamijoyo/tfupdate@latest

# Install terrascan
RUN git clone https://github.com/tenable/terrascan.git && \
    cd terrascan && \
    make build

# Start a new stage for the runtime
FROM alpine:latest

# Copy the Go binaries from the builder stage
COPY --from=builder /go/bin/terraform-docs /usr/local/bin/
COPY --from=builder /go/bin/tfsec /usr/local/bin/
COPY --from=builder /go/bin/tfupdate /usr/local/bin/
COPY --from=builder /go/terrascan/bin/terrascan /usr/local/bin/

# Install runtime dependencies
RUN apk update && apk add --no-cache \
    curl \
    bash \
    jq \
    py3-pip \
    unzip

# Upgrade pip and setuptools, and install checkov and pre-commit
RUN pip3 install --upgrade pip setuptools && \
    pip3 install checkov pre-commit

# Install tflint
RUN curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Fetch the latest version of Terraform
RUN TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version') && \
    curl -LO https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip

CMD ["/bin/sh"]
