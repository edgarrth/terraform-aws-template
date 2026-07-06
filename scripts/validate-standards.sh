#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"
LAYER="${2:-all}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_ROOT="$ROOT_DIR/terraform/live/$ENVIRONMENT"

if ! command -v terraform >/dev/null; then
  echo "terraform is required" >&2
  exit 1
fi

layers=(foundation network platform data observability)
if [[ "$LAYER" != "all" ]]; then
  layers=("$LAYER")
fi

echo "==> Terraform format normalization"
terraform -chdir="$ROOT_DIR/terraform" fmt -recursive

echo "==> Static corporate standards validation"
python3 "$ROOT_DIR/scripts/validate-standards.py" "$ENVIRONMENT" "$LAYER"

for layer in "${layers[@]}"; do
  dir="$TF_ROOT/$layer"
  if [[ ! -d "$dir" ]]; then
    echo "Layer directory does not exist: $dir" >&2
    exit 1
  fi

  echo "==> Terraform init/validate: $ENVIRONMENT/$layer"
  terraform -chdir="$dir" init -backend=false -input=false
  terraform -chdir="$dir" validate

done

echo "Standards validation completed successfully."
