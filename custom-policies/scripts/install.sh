#!/usr/bin/env bash
# Installs or upgrades the n4k-policies Helm chart in four batches of ~10
# policies each, avoiding Kyverno's 10s webhook timeout that fires when all
# 38 ClusterPolicy resources are created simultaneously.
#
# Usage:
#   ./scripts/install.sh [release-name] [namespace] [chart-path]
#
# Defaults:
#   release-name : n4k-policies
#   namespace    : kyverno
#   chart-path   : . (current directory, i.e. the chart root)
set -euo pipefail

RELEASE="${1:-n4k-policies}"
NAMESPACE="${2:-kyverno}"
CHART="${3:-.}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Release:   $RELEASE"
echo "==> Namespace: $NAMESPACE"
echo "==> Chart:     $CHART"
echo ""

helm_args=(
  --namespace "$NAMESPACE"
  --create-namespace
)

echo "[1/4] Installing batch 1 (policies 1-10)..."
helm upgrade --install "$RELEASE" "$CHART" "${helm_args[@]}" \
  -f "$SCRIPTS_DIR/values-batch1.yaml"

echo "[2/4] Upgrading with batch 2 (+10 policies, total 20)..."
helm upgrade "$RELEASE" "$CHART" "${helm_args[@]}" \
  -f "$SCRIPTS_DIR/values-batch2.yaml"

echo "[3/4] Upgrading with batch 3 (+10 policies, total 30)..."
helm upgrade "$RELEASE" "$CHART" "${helm_args[@]}" \
  -f "$SCRIPTS_DIR/values-batch3.yaml"

echo "[4/4] Final upgrade — all 38 policies enabled..."
helm upgrade "$RELEASE" "$CHART" "${helm_args[@]}" \
  --set customPolicies.enabled=true

echo ""
echo "==> Install complete. Verifying..."
DEPLOYED=$(kubectl get clusterpolicy --no-headers 2>/dev/null | wc -l | tr -d ' ')
echo "==> ClusterPolicies deployed: $DEPLOYED"

NOT_READY=$(kubectl get clusterpolicy --no-headers 2>/dev/null | awk '$4 != "True"' | wc -l | tr -d ' ')
if [ "$NOT_READY" -gt 0 ]; then
  echo "WARNING: $NOT_READY policies are not Ready:"
  kubectl get clusterpolicy --no-headers | awk '$4 != "True" {print "  " $1, $4, $5}'
else
  echo "==> All $DEPLOYED policies are Ready."
fi
