#!/usr/bin/env python3
"""
Static corporate standards validator for this Terraform template.
It does not require AWS credentials. It validates:
- mandatory FinOps/common tags in terraform/globals/tags.tfvars
- allowed values for key tags
- layer/environment tfvars include common tags
- common resource naming style in Terraform source files
- production data resources require backup/dr flags through common tags
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

ROOT = Path(__file__).resolve().parents[1]
TERRAFORM_DIR = ROOT / "terraform"

REQUIRED_TAGS = {
    "organization", "business_unit", "domain", "application", "component", "environment",
    "owner", "technical_owner", "cost_center", "product", "squad", "criticality",
    "data_classification", "compliance", "managed_by", "repository", "lifecycle",
    "backup_required", "dr_required", "finops_allocation",
}

ALLOWED_VALUES = {
    "environment": {"dev", "qa", "stg", "uat", "prod", "prd", "dr", "sbx"},
    "criticality": {"low", "medium", "high", "critical"},
    "data_classification": {"public", "internal", "confidential", "restricted"},
    "managed_by": {"terraform", "terragrunt", "helm", "argocd", "ansible", "manual-exception"},
    "lifecycle": {"experimental", "active", "deprecated", "retired"},
    "finops_allocation": {"direct", "shared", "platform", "security", "networking", "observability"},
    "backup_required": {"true", "false"},
    "dr_required": {"true", "false"},
}

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
TF_LOCAL_NAME_RE = re.compile(r"^[A-Za-z0-9_]+$")
TAG_LINE_RE = re.compile(r'^\s*([A-Za-z0-9_]+)\s*=\s*"?([^"\n#]+)"?\s*(?:#.*)?$')
RESOURCE_RE = re.compile(r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"')
NAME_ATTR_RE = re.compile(r'^\s*(name|bucket|identifier|cluster_identifier|queue_name|topic_name)\s*=\s*"([^"]+)"')
TAGS_REF_RE = re.compile(r'tags\s*=\s*(?:var\.common_tags|local\.common_tags|merge\()')

SKIP_RESOURCE_TAGS = {
    "aws_ecr_lifecycle_policy",
    "aws_iam_role_policy_attachment",
    "aws_kms_alias",
    "aws_route_table_association",
    "aws_security_group_rule",
    "aws_secretsmanager_secret_version",
    "aws_sns_topic_subscription",
    "aws_sqs_queue_policy",
    "aws_vpc_endpoint_route_table_association",
    "aws_vpc_endpoint_subnet_association",
}


def parse_tfvars(path: Path) -> Dict[str, str]:
    values: Dict[str, str] = {}
    if not path.exists():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        m = TAG_LINE_RE.match(line)
        if m:
            values[m.group(1)] = m.group(2).strip().strip('"')
    return values


def iter_tf_files() -> List[Path]:
    return sorted(p for p in TERRAFORM_DIR.rglob("*.tf") if ".terraform" not in p.parts)


def check_global_tags(errors: List[str], warnings: List[str]) -> None:
    tag_file = TERRAFORM_DIR / "globals" / "tags.tfvars"
    tags = parse_tfvars(tag_file)
    if not tags:
        errors.append(f"Missing or empty global tags file: {tag_file.relative_to(ROOT)}")
        return

    missing = sorted(REQUIRED_TAGS - set(tags))
    if missing:
        errors.append(f"terraform/globals/tags.tfvars is missing required tags: {', '.join(missing)}")

    for key, allowed in ALLOWED_VALUES.items():
        if key in tags and tags[key] not in allowed:
            errors.append(
                f"terraform/globals/tags.tfvars has invalid value for {key}: '{tags[key]}'. Allowed: {', '.join(sorted(allowed))}"
            )

    if tags.get("lifecycle") == "experimental" and "expiration_date" not in tags:
        errors.append("Experimental resources must define expiration_date in common tags.")

    if tags.get("environment") in {"prod", "prd"}:
        if tags.get("backup_required") != "true":
            errors.append("Production common tags must set backup_required=true.")
        if tags.get("dr_required") != "true":
            errors.append("Production common tags must set dr_required=true.")

    if tags.get("finops_allocation") == "shared" and "allocation_rule" not in tags:
        warnings.append("Shared cost resources should include allocation_rule to support FinOps showback/chargeback.")


def check_layer_tfvars(errors: List[str], workload: str | None = None, environment: str | None = None, layer: str = "all") -> None:
    pattern = "*/*/*/terraform.tfvars"
    candidates = sorted((TERRAFORM_DIR / "live").glob(pattern))
    for tfvars in candidates:
        rel_parts = tfvars.relative_to(TERRAFORM_DIR / "live").parts
        current_workload, current_environment, current_layer = rel_parts[0], rel_parts[1], rel_parts[2]
        if workload and current_workload != workload:
            continue
        if environment and current_environment != environment:
            continue
        if layer != "all" and current_layer != layer:
            continue
        values = parse_tfvars(tfvars)
        missing = [k for k in ["environment", "domain", "application", "component"] if k not in values]
        if missing:
            errors.append(f"{tfvars.relative_to(ROOT)} is missing mandatory context variables: {', '.join(missing)}")


def block_text(lines: List[str], start: int) -> Tuple[str, int]:
    depth = 0
    chunk = []
    for i in range(start, len(lines)):
        line = lines[i]
        depth += line.count("{") - line.count("}")
        chunk.append(line)
        if i > start and depth <= 0:
            return "\n".join(chunk), i
    return "\n".join(chunk), len(lines) - 1


def check_terraform_resources(errors: List[str], warnings: List[str]) -> None:
    for path in iter_tf_files():
        rel = path.relative_to(ROOT)
        lines = path.read_text(encoding="utf-8").splitlines()
        i = 0
        while i < len(lines):
            m = RESOURCE_RE.match(lines[i])
            if not m:
                i += 1
                continue

            resource_type, local_name = m.group(1), m.group(2)
            block, end = block_text(lines, i)
            address = f"{rel}:{i + 1} resource.{resource_type}.{local_name}"

            # Terraform local labels are code identifiers used in references. Underscores are valid and recommended here.
            # Corporate naming conventions are enforced on the cloud resource name attributes below.
            if not TF_LOCAL_NAME_RE.match(local_name):
                errors.append(f"{address} has invalid Terraform local label '{local_name}'. Use letters, numbers and underscores only.")

            name_matches = NAME_ATTR_RE.findall(block)
            for attr, value in name_matches:
                if "${" in value:
                    continue
                if not NAME_RE.match(value) and resource_type not in {"aws_cloudwatch_log_group", "aws_secretsmanager_secret"}:
                    errors.append(f"{address} has invalid {attr}='{value}'. Use lowercase kebab-case.")

            if resource_type not in SKIP_RESOURCE_TAGS and resource_type.startswith("aws_"):
                if not TAGS_REF_RE.search(block) and "tags_all" not in block:
                    warnings.append(f"{address} should use common tags through var.common_tags/local.common_tags/merge().")

            i = end + 1


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("workload", nargs="?", default="payments")
    parser.add_argument("environment", nargs="?", default="dev")
    parser.add_argument("layer", nargs="?", default="all")
    args = parser.parse_args()

    errors: List[str] = []
    warnings: List[str] = []

    live_workload_path = TERRAFORM_DIR / "live" / args.workload
    if not live_workload_path.exists():
        errors.append(f"Workload does not exist under terraform/live: {args.workload}")
    if args.environment not in {"dev", "qa", "prod"}:
        errors.append("Environment must be one of: dev, qa, prod")
    if args.layer not in {"all", "foundation", "network", "platform", "data", "observability"}:
        errors.append("Layer must be one of: all, foundation, network, platform, data, observability")

    check_global_tags(errors, warnings)
    check_layer_tfvars(errors, args.workload, args.environment, args.layer)
    check_terraform_resources(errors, warnings)

    for warning in warnings:
        print(f"::warning::{warning}")

    if errors:
        print("\nStandards validation failed:\n", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Standards validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
