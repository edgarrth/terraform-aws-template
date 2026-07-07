#!/usr/bin/env python3
"""
Repository structure validator for this Terraform Landing Zone Workload template.

Important:
- Corporate policy rules for naming, tags, FinOps and allowed values live in policy/terraform_standards.rego.
- This script intentionally does NOT duplicate those policy lists.
- This script validates repository concerns that are easier to check before Terraform plan/OPA, such as folder layout,
  required files, workload/environment/layer structure, module paths and CI/CD wiring.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Iterable, List

ROOT = Path(__file__).resolve().parents[1]
TERRAFORM_DIR = ROOT / "terraform"

VALID_ENVIRONMENTS = {"dev", "qa", "prod"}
VALID_LAYERS = {"foundation", "network", "platform", "data", "observability"}
REQUIRED_TOP_LEVEL_DIRS = [".github/workflows", "ansible", "docs/standards", "policy", "scripts", "terraform"]
REQUIRED_TERRAFORM_DIRS = ["backend", "globals", "live", "modules"]
REQUIRED_MODULE_DOMAINS = ["foundation", "network", "platform", "data", "observability", "governance"]
REQUIRED_LAYER_FILES = ["backend.tf", "main.tf", "outputs.tf", "providers.tf", "terraform.tfvars", "variables.tf"]
REQUIRED_WORKFLOWS = ["validate-standards.yml", "deploy.yml"]
RESOURCE_RE = re.compile(r'^\s*resource\s+"([^"]+)"\s+"([^"]+)"')
TF_LOCAL_NAME_RE = re.compile(r"^[A-Za-z0-9_]+$")
MODULE_SOURCE_RE = re.compile(r'source\s*=\s*"([^"]+)"')


def rel(path: Path) -> str:
    return str(path.relative_to(ROOT))


def add_missing_dir_errors(errors: List[str], base: Path, dirs: Iterable[str]) -> None:
    for directory in dirs:
        path = base / directory
        if not path.exists() or not path.is_dir():
            errors.append(f"Missing required directory: {rel(path)}")


def check_required_files(errors: List[str]) -> None:
    required_files = [
        ROOT / "README.md",
        ROOT / "policy" / "terraform_standards.rego",
        ROOT / "scripts" / "validate-standards.sh",
        ROOT / "scripts" / "validate-standards.py",
        ROOT / "scripts" / "deploy.sh",
        ROOT / ".checkov.yml",
    ]
    for path in required_files:
        if not path.exists() or not path.is_file():
            errors.append(f"Missing required file: {rel(path)}")

    for workflow in REQUIRED_WORKFLOWS:
        path = ROOT / ".github" / "workflows" / workflow
        if not path.exists() or not path.is_file():
            errors.append(f"Missing required workflow: {rel(path)}")


def check_module_domains(errors: List[str]) -> None:
    modules_dir = TERRAFORM_DIR / "modules"
    add_missing_dir_errors(errors, modules_dir, REQUIRED_MODULE_DOMAINS)

    allowed = set(REQUIRED_MODULE_DOMAINS)
    for child in modules_dir.iterdir() if modules_dir.exists() else []:
        if child.is_dir() and child.name not in allowed:
            errors.append(f"Module domain outside Landing Zone structure: {rel(child)}")

    governance_readme = modules_dir / "governance" / "README.md"
    if not governance_readme.exists():
        errors.append(f"Governance module domain must contain a README because it is a policy/documentation domain: {rel(governance_readme)}")


def check_live_structure(errors: List[str], workload: str, environment: str, layer: str) -> None:
    live_dir = TERRAFORM_DIR / "live"
    if not live_dir.exists():
        errors.append(f"Missing live directory: {rel(live_dir)}")
        return

    workload_dir = live_dir / workload
    if not workload_dir.exists():
        errors.append(f"Workload does not exist under terraform/live: {workload}")
        return

    env_dir = workload_dir / environment
    if not env_dir.exists():
        errors.append(f"Environment does not exist for workload {workload}: {environment}")
        return

    layers = sorted(VALID_LAYERS) if layer == "all" else [layer]
    for current_layer in layers:
        layer_dir = env_dir / current_layer
        if not layer_dir.exists():
            errors.append(f"Layer directory does not exist: {rel(layer_dir)}")
            continue
        for required_file in REQUIRED_LAYER_FILES:
            path = layer_dir / required_file
            if not path.exists():
                errors.append(f"Missing required layer file: {rel(path)}")


def check_module_sources(errors: List[str]) -> None:
    live_tf_files = sorted((TERRAFORM_DIR / "live").rglob("*.tf"))
    for tf_file in live_tf_files:
        content = tf_file.read_text(encoding="utf-8")
        for source in MODULE_SOURCE_RE.findall(content):
            if source.startswith("../") or source.startswith("./"):
                resolved = (tf_file.parent / source).resolve()
                if not resolved.exists():
                    errors.append(f"Invalid local module source in {rel(tf_file)}: {source}")


def check_terraform_local_labels(errors: List[str]) -> None:
    for tf_file in sorted(TERRAFORM_DIR.rglob("*.tf")):
        if ".terraform" in tf_file.parts:
            continue
        for line_number, line in enumerate(tf_file.read_text(encoding="utf-8").splitlines(), start=1):
            match = RESOURCE_RE.match(line)
            if not match:
                continue
            local_name = match.group(2)
            if not TF_LOCAL_NAME_RE.match(local_name):
                errors.append(
                    f"{rel(tf_file)}:{line_number} has invalid Terraform local label '{local_name}'. Use letters, numbers and underscores only."
                )


def check_workflow_sarif_artifact(errors: List[str], warnings: List[str]) -> None:
    workflow = ROOT / ".github" / "workflows" / "validate-standards.yml"
    if not workflow.exists():
        return
    content = workflow.read_text(encoding="utf-8")
    if "upload-sarif" not in content:
        errors.append("validate-standards.yml must upload Checkov SARIF to GitHub Code Scanning.")
    if "actions/upload-artifact" not in content or "checkov-results.sarif" not in content:
        errors.append("validate-standards.yml must store checkov-results.sarif as a downloadable artifact.")
    if "continue-on-error: true" in content and "soft_fail: true" in content:
        warnings.append("Checkov is configured as advisory/soft-fail; corporate standards remain blocking.")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("workload", nargs="?", default="payments")
    parser.add_argument("environment", nargs="?", default="dev")
    parser.add_argument("layer", nargs="?", default="all")
    args = parser.parse_args()

    errors: List[str] = []
    warnings: List[str] = []

    if args.environment not in VALID_ENVIRONMENTS:
        errors.append("Environment must be one of: dev, qa, prod")
    if args.layer != "all" and args.layer not in VALID_LAYERS:
        errors.append("Layer must be one of: all, foundation, network, platform, data, observability")

    add_missing_dir_errors(errors, ROOT, REQUIRED_TOP_LEVEL_DIRS)
    add_missing_dir_errors(errors, TERRAFORM_DIR, REQUIRED_TERRAFORM_DIRS)
    check_required_files(errors)
    check_module_domains(errors)
    check_live_structure(errors, args.workload, args.environment, args.layer)
    check_module_sources(errors)
    check_terraform_local_labels(errors)
    check_workflow_sarif_artifact(errors, warnings)

    for warning in warnings:
        print(f"::warning::{warning}")

    if errors:
        print("\nRepository structure validation failed:\n", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Repository structure validation passed.")
    print("Corporate naming, tagging, FinOps and allowed-value policies are defined in policy/terraform_standards.rego.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
