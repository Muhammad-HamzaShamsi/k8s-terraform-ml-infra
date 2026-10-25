#!/usr/bin/env bash
# Tear everything down (load balancers first so the VPC can be deleted cleanly).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl delete -k "$ROOT/k8s" --ignore-not-found || true
helm uninstall ingress-nginx -n ingress-nginx || true
helm uninstall monitoring -n monitoring || true
terraform -chdir="$ROOT/terraform" destroy -auto-approve
