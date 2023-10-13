#!/bin/bash
set -e

# Ensure we're using the latest Terraform version
tfenv use latest

# Run the CMD from the Dockerfile, passed as arguments to this script
exec "$@"
