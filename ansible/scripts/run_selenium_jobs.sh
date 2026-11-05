#!/bin/bash
set -euo pipefail

export PATH="$PATH:/usr/local/bin"

WORKSPACE="${WORKSPACE:-$(pwd)}"

: "${MASTER_PUBLIC_IP:?MASTER_PUBLIC_IP is required}"

echo "=== Running Petclinic Selenium Tests ==="

ansible-playbook \
  --connection=local \
  --inventory 127.0.0.1, \
  --extra-vars "workspace=${WORKSPACE} master_public_ip=${MASTER_PUBLIC_IP}" \
  ./ansible/playbooks/pb_run_selenium_jobs.yaml

echo "SUCCESS: All Selenium tests completed!"
