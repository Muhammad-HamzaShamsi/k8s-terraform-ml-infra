#!/usr/bin/env bash
# Provision infrastructure and deploy the model API + monitoring stack end to end.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> Terraform: provisioning VPC, EKS, ECR, S3"
terraform -chdir="$ROOT/terraform" init -upgrade
terraform -chdir="$ROOT/terraform" apply -auto-approve

REGION="$(terraform -chdir="$ROOT/terraform" output -raw configure_kubectl | awk '{print $5}')"
CLUSTER="$(terraform -chdir="$ROOT/terraform" output -raw cluster_name)"

echo "==> Configuring kubectl for $CLUSTER ($REGION)"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER"

echo "==> Installing cluster add-ons via Helm"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx >/dev/null
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/ >/dev/null
helm repo update >/dev/null

helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  -n ingress-nginx --create-namespace
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace -f "$ROOT/monitoring/kube-prometheus-stack-values.yaml"

echo "==> Deploying model API"
kubectl apply -k "$ROOT/k8s"
kubectl apply -f "$ROOT/monitoring/servicemonitor.yaml" -f "$ROOT/monitoring/alerts.yaml"
kubectl -n ml-serving rollout status deploy/model-api --timeout=180s

echo "==> Done. Ingress address:"
kubectl -n ingress-nginx get svc ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
