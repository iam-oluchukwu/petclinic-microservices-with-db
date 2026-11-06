#!/bin/bash
set -euo pipefail

export PATH="$PATH:/usr/local/bin"

WORKSPACE="${WORKSPACE:-$(pwd)}"

echo "=== Running Dummy Selenium Test ==="

ansible-playbook \
  --connection=local \
  --inventory 127.0.0.1, \
  --extra-vars "workspace=${WORKSPACE}" \
  ./ansible/playbooks/pb_run_dummy_selenium_job.yaml

echo "SUCCESS: Selenium test execution completed!"
