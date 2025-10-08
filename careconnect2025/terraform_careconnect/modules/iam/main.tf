resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0

  name               = var.role_name
  assume_role_policy = var.assume_role_policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.create_role ? toset(var.managed_policy_arns) : []

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "inline" {
  for_each = var.create_role ? var.inline_policies : {}

  name   = each.key
  role   = aws_iam_role.this[0].id
  policy = each.value.policy
}

resource "aws_iam_policy" "this" {
  for_each = var.custom_policies

  name        = each.key
  description = lookup(each.value, "description", null)
  policy      = each.value.policy

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each = var.create_role ? var.custom_policies : {}

  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[each.key].arn
}
