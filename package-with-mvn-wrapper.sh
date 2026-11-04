#!/usr/bin/env bash

# Stop if a command fails or an unset variable is used
set -euo pipefail

# Move to the project directory
cd "$(dirname "$0")"

# Clean, compile, test, and package the application
./mvnw clean package
