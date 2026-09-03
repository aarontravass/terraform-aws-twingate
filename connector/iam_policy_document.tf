data "aws_iam_policy_document" "ecs_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "read_secrets_policy" {
  statement {
    resources = [aws_secretsmanager_secret.this.arn]
    actions   = ["secretsmanager:GetSecretValue"]
  }
}

resource "aws_iam_policy" "read_secrets_policy" {
  name   = "twingate-${twingate_connector.this.name}-read-secrets"
  policy = data.aws_iam_policy_document.read_secrets_policy.json
  tags = merge(var.tags, {
    name = "twingate-${twingate_connector.this.name}-read-secrets"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_read_secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.read_secrets_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_read_secrets" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.read_secrets_policy.arn
}
