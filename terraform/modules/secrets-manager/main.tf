resource "aws_secretsmanager_secret" "this" {
  for_each    = var.secrets
  name        = each.key
  description = each.value.description
  kms_key_id  = var.kms_key_id
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  for_each      = var.secrets
  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_value
}
