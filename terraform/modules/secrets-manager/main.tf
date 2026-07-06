resource "aws_secretsmanager_secret" "this" {
  # var.secrets is sensitive because it contains secret_value.
  # Terraform does not allow sensitive values directly in for_each because
  # instance keys are exposed in state/plans. The secret names are intentionally
  # declassified because they are resource identifiers, not secret material.
  for_each    = nonsensitive(toset(keys(var.secrets)))
  name        = each.key
  description = var.secrets[each.key].description
  kms_key_id  = var.kms_key_id
  tags        = merge(var.tags, { Name = each.key })
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = nonsensitive(toset(keys(var.secrets)))
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = var.secrets[each.key].secret_value
}
