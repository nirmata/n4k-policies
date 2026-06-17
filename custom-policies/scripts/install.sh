#!/usr/bin/env bash
# Installs n4k-policies in four batches to avoid Kyverno's 10s webhook timeout.
# Usage: ./custom-policies/scripts/install.sh [release] [namespace] [chart-path]
# Defaults: n4k-policies kyverno .
set -euo pipefail

RELEASE="${1:-n4k-policies}"
NAMESPACE="${2:-kyverno}"
CHART="${3:-.}"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

helm_args=(--namespace "$NAMESPACE" --create-namespace)
PREV_POLICIES=""

run() {
  helm "$@" > /dev/null || exit 1
}

show_new() {
  local current
  current=$(kubectl get clusterpolicy --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | sort)
  if [ -z "$PREV_POLICIES" ]; then
    echo "$current" | awk '{print "  + " $0}'
  else
    comm -13 <(echo "$PREV_POLICIES") <(echo "$current") | awk '{print "  + " $0}'
  fi
  PREV_POLICIES="$current"
}

echo "Release: $RELEASE | Namespace: $NAMESPACE"

echo "[1/4] Batch 1..."
run upgrade --install "$RELEASE" "$CHART" "${helm_args[@]}" -f "$SCRIPTS_DIR/values-batch1.yaml"
show_new

echo "[2/4] Batch 2..."
run upgrade "$RELEASE" "$CHART" "${helm_args[@]}" -f "$SCRIPTS_DIR/values-batch2.yaml"
show_new

echo "[3/4] Batch 3..."
run upgrade "$RELEASE" "$CHART" "${helm_args[@]}" -f "$SCRIPTS_DIR/values-batch3.yaml"
show_new

echo "[4/4] Batch 4..."
run upgrade "$RELEASE" "$CHART" "${helm_args[@]}" --set customPolicies.enabled=true
show_new

echo "Done."
