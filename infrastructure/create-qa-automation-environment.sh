#!/usr/bin/env bash
set -euo pipefail

# MSP-16: Petclinic QA Automation Environment
# Run each stage separately.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT/infrastructure/dev-k8s-terraform"
INVENTORY="$ROOT/ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml"
PLAYBOOK="$ROOT/ansible/playbooks/k8s_setup.yaml"

export AWS_REGION="${AWS_REGION:-us-east-1}"
export AWS_DEFAULT_REGION="$AWS_REGION"
export PATH="$PATH:/usr/local/bin"

STAGE="${1:-help}"

require_cidr() {
  : "${ADMIN_CIDR:?Set ADMIN_CIDR to your current public IPv4/32}"
}

case "$STAGE" in

  plan|apply|destroy)
    require_cidr

    terraform -chdir="$TF_DIR" init -input=false

    terraform -chdir="$TF_DIR" "$STAGE" \
      -var="admin_cidr=$ADMIN_CIDR"
    ;;

  status)
    echo "=== Terraform resources ==="
    terraform -chdir="$TF_DIR" state list
    ;;

  validate)
    echo "=== Validate Kubernetes playbook ==="

    test -s "$INVENTORY"
    test -s "$PLAYBOOK"

    ansible-playbook \
      -i "$INVENTORY" \
      "$PLAYBOOK" \
      --syntax-check
    ;;

  install)
    echo "=== Install Kubernetes using Ansible ==="

    test -s "$INVENTORY"
    test -s "$PLAYBOOK"

    export ANSIBLE_PRIVATE_KEY_FILE="${K8S_SSH_KEY:-${ANSIBLE_PRIVATE_KEY_FILE:-}}"

    if [[ -z "$ANSIBLE_PRIVATE_KEY_FILE" ]] || \
       [[ ! -s "$ANSIBLE_PRIVATE_KEY_FILE" ]]; then
      echo "ERROR: Kubernetes SSH credential is missing."
      exit 1
    fi

    KNOWN_HOSTS="${K8S_KNOWN_HOSTS:-$ROOT/.ssh_known_hosts}"

    if [[ ! -s "$KNOWN_HOSTS" ]]; then
      echo "ERROR: Verified SSH known_hosts file is missing."
      exit 1
    fi

    export ANSIBLE_HOST_KEY_CHECKING=True
    export ANSIBLE_SSH_COMMON_ARGS="-o UserKnownHostsFile=$KNOWN_HOSTS -o StrictHostKeyChecking=yes -o IdentitiesOnly=yes -o ConnectTimeout=10"

    echo "=== Check target inventory ==="
    ansible-inventory -i "$INVENTORY" --list |
      python3 -c '
import json, sys
inventory = json.load(sys.stdin)
for group, expected in [("role_master", 1), ("role_worker", 2)]:
    actual = len(inventory.get(group, {}).get("hosts", []))
    print(f"{group}: {actual}")
    if actual != expected:
        sys.exit(f"ERROR: Expected {expected} hosts in {group}")
'

    echo "=== Verify connectivity ==="
    ansible -i "$INVENTORY" all -m ping

    echo "=== Configure Kubernetes ==="
    ansible-playbook \
      -i "$INVENTORY" \
      "$PLAYBOOK"

    echo "SUCCESS: Kubernetes installation completed."
    ;;

  help)
    echo "Petclinic QA Automation Environment"
    echo ""
    echo "Usage: $0 STAGE"
    echo ""
    echo "Available stages:"
    echo "  status    Show Terraform resources"
    echo "  plan      Preview infrastructure"
    echo "  apply     Provision Kubernetes EC2 nodes"
    echo "  validate  Check Ansible playbook syntax"
    echo "  install   Install Kubernetes on provisioned nodes"
    echo "  destroy   Tear down Terraform infrastructure"
    echo ""
    echo "For Terraform stages, set ADMIN_CIDR."
    ;;

  *)
    echo "Unknown stage: $STAGE"
    exit 1
    ;;
esac
