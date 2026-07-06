package terraform.standards

required_tags := {
  "organization", "business_unit", "domain", "application", "component", "environment",
  "owner", "technical_owner", "cost_center", "product", "squad", "criticality",
  "data_classification", "compliance", "managed_by", "repository", "lifecycle",
  "backup_required", "dr_required", "finops_allocation"
}

valid_envs := {"dev", "qa", "stg", "uat", "prod", "dr", "sbx"}
valid_criticality := {"low", "medium", "high", "critical"}
valid_data_classification := {"public", "internal", "confidential", "restricted"}
valid_managed_by := {"terraform", "terragrunt", "helm", "argocd", "ansible", "manual-exception"}
valid_lifecycle := {"experimental", "active", "deprecated", "retired"}
valid_finops_allocation := {"direct", "shared", "platform", "security", "networking", "observability"}

resources[r] {
  r := input.resource_changes[_]
  r.mode == "managed"
  actions := {a | a := r.change.actions[_]}
  not actions["delete"]
}

tagged_resources[r] {
  r := resources[_]
  object.get(r.change.after, "tags", null) != null
}

tagged_resources[r] {
  r := resources[_]
  object.get(r.change.after, "tags_all", null) != null
}

tags(r) := object.get(r.change.after, "tags_all", object.get(r.change.after, "tags", {}))
resource_name(r) := object.get(r.change.after, "name", object.get(r.change.after, "bucket", object.get(r.change.after, "identifier", "")))

deny[msg] {
  r := tagged_resources[_]
  missing := required_tags - {t | tags(r)[t]}
  count(missing) > 0
  msg := sprintf("%s is missing required tags: %v", [r.address, missing])
}

deny[msg] { r := tagged_resources[_]; env := tags(r)["environment"]; not valid_envs[env]; msg := sprintf("%s has invalid environment tag: %s", [r.address, env]) }
deny[msg] { r := tagged_resources[_]; v := tags(r)["criticality"]; not valid_criticality[v]; msg := sprintf("%s has invalid criticality tag: %s", [r.address, v]) }
deny[msg] { r := tagged_resources[_]; v := tags(r)["data_classification"]; not valid_data_classification[v]; msg := sprintf("%s has invalid data_classification tag: %s", [r.address, v]) }
deny[msg] { r := tagged_resources[_]; v := tags(r)["managed_by"]; not valid_managed_by[v]; msg := sprintf("%s has invalid managed_by tag: %s", [r.address, v]) }
deny[msg] { r := tagged_resources[_]; v := tags(r)["lifecycle"]; not valid_lifecycle[v]; msg := sprintf("%s has invalid lifecycle tag: %s", [r.address, v]) }
deny[msg] { r := tagged_resources[_]; v := tags(r)["finops_allocation"]; not valid_finops_allocation[v]; msg := sprintf("%s has invalid finops_allocation tag: %s", [r.address, v]) }

deny[msg] {
  r := tagged_resources[_]
  n := resource_name(r)
  n != ""
  not regex.match("^[a-z0-9]+(-[a-z0-9]+)*$", n)
  msg := sprintf("%s has invalid name '%s'. Use lowercase kebab-case.", [r.address, n])
}

deny[msg] {
  r := tagged_resources[_]
  tags(r)["lifecycle"] == "experimental"
  not tags(r)["expiration_date"]
  msg := sprintf("%s is experimental and must define expiration_date", [r.address])
}

deny[msg] {
  r := tagged_resources[_]
  tags(r)["environment"] == "prod"
  data_resource_types[r.type]
  tags(r)["backup_required"] != "true"
  msg := sprintf("%s is production data resource and must have backup_required=true", [r.address])
}

data_resource_types := {"aws_db_instance", "aws_rds_cluster", "aws_dynamodb_table"}

deny[msg] {
  r := resources[_]
  r.type == "aws_s3_bucket_public_access_block"
  not r.change.after.block_public_acls
  msg := sprintf("%s must block public ACLs", [r.address])
}

deny[msg] {
  r := resources[_]
  r.type == "aws_security_group_rule"
  r.change.after.cidr_blocks[_] == "0.0.0.0/0"
  r.change.after.from_port != 443
  msg := sprintf("%s exposes non-HTTPS traffic to 0.0.0.0/0", [r.address])
}
