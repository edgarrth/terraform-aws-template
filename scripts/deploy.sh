#!/usr/bin/env bash
set -euo pipefail

WORKLOAD="${1:?Usage: ./scripts/deploy.sh <workload> <environment> <layer> [plan|apply|destroy]}"
ENVIRONMENT="${2:?Usage: ./scripts/deploy.sh <workload> <environment> <layer> [plan|apply|destroy]}"
LAYER="${3:?Usage: ./scripts/deploy.sh <workload> <environment> <layer> [plan|apply|destroy]}"
ACTION="${4:-plan}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$ROOT_DIR/terraform/live/$WORKLOAD/$ENVIRONMENT/$LAYER"
BACKEND="$ROOT_DIR/terraform/backend/$ENVIRONMENT.hcl"
PLAN_FILE="tfplan.binary"
PLAN_JSON="tfplan.json"
POLICY_DIR="$ROOT_DIR/policy"

if [[ ! -d "$DIR" ]]; then echo "Layer not found: $DIR" >&2; exit 1; fi
if [[ ! -f "$BACKEND" ]]; then echo "Backend not found: $BACKEND" >&2; exit 1; fi

run_policy_validation() {
  if command -v conftest >/dev/null 2>&1; then
    echo "==> Validating Terraform plan with OPA/Conftest policies"
    terraform -chdir="$DIR" show -json "$PLAN_FILE" > "$DIR/$PLAN_JSON"
    conftest test "$DIR/$PLAN_JSON" --policy "$POLICY_DIR" --namespace terraform.standards
  else
    echo "conftest is not installed; skipping OPA/Rego policy validation for the Terraform plan." >&2
    echo "Install conftest in CI/CD to enforce policy/terraform_standards.rego before apply." >&2
  fi
}

terraform -chdir="$DIR" init \
  -backend-config="$BACKEND" \
  -backend-config="key=$WORKLOAD/$ENVIRONMENT/$LAYER/terraform.tfstate" \
  -input=false

case "$ACTION" in
  plan)
    terraform -chdir="$DIR" plan -out="$PLAN_FILE" -input=false
    run_policy_validation
    ;;
  apply)
    terraform -chdir="$DIR" plan -out="$PLAN_FILE" -input=false
    run_policy_validation
    terraform -chdir="$DIR" apply -input=false "$PLAN_FILE"
    ;;
  destroy)
    terraform -chdir="$DIR" destroy -input=false
    ;;
  *) echo "Invalid action: $ACTION" >&2; exit 1 ;;
esac
