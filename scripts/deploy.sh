#!/usr/bin/env bash
set -euo pipefail

WORKLOAD="${1:?Usage: ./scripts/deploy.sh <workload> <environment> <layer> [plan|apply|destroy]}"
ENVIRONMENT="${2:?Usage: ./scripts/deploy.sh <workload> <environment> <layer> [plan|apply|destroy]}"
LAYER="${3:?Usage: ./scripts/deploy.sh <workload> <environment> <layer> [plan|apply|destroy]}"
ACTION="${4:-plan}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT_DIR/terraform/live/$WORKLOAD/$ENVIRONMENT/$LAYER"
BACKEND="$ROOT_DIR/terraform/backend/$ENVIRONMENT.hcl"

if [[ ! -d "$DIR" ]]; then echo "Layer not found: $DIR" >&2; exit 1; fi
if [[ ! -f "$BACKEND" ]]; then echo "Backend not found: $BACKEND" >&2; exit 1; fi

terraform -chdir="$DIR" init \
  -backend-config="$BACKEND" \
  -backend-config="key=$WORKLOAD/$ENVIRONMENT/$LAYER/terraform.tfstate" \
  -input=false

case "$ACTION" in
  plan) terraform -chdir="$DIR" plan -input=false ;;
  apply) terraform -chdir="$DIR" apply -input=false ;;
  destroy) terraform -chdir="$DIR" destroy -input=false ;;
  *) echo "Invalid action: $ACTION" >&2; exit 1 ;;
esac
