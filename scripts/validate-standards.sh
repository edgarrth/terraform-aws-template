#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
LAYER="${2:-all}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_ROOT="$ROOT_DIR/terraform/live/$ENVIRONMENT"
POLICY_DIR="$ROOT_DIR/policy"

if ! command -v terraform >/dev/null; then echo "terraform is required" >&2; exit 1; fi
if ! command -v conftest >/dev/null; then echo "conftest is required" >&2; exit 1; fi

layers=(foundation network platform data observability)
if [[ "$LAYER" != "all" ]]; then layers=("$LAYER"); fi

terraform -chdir="$ROOT_DIR/terraform" fmt -check -recursive

for layer in "${layers[@]}"; do
  dir="$TF_ROOT/$layer"
  echo "==> Validating $ENVIRONMENT/$layer"
  terraform -chdir="$dir" init -backend=false -input=false
  terraform -chdir="$dir" validate
  terraform -chdir="$dir" plan -lock=false -input=false -out=tfplan.binary
  terraform -chdir="$dir" show -json tfplan.binary > "$dir/tfplan.json"
  conftest test "$dir/tfplan.json" --policy "$POLICY_DIR" --namespace terraform.standards
  rm -f "$dir/tfplan.binary" "$dir/tfplan.json"
done
