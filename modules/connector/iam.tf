# role assumed when a task is started/executed
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "twingate-${twingate_connector.this.name}-${local.aws.region}-exe"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
  tags               = var.tags
}

# role assumed when the task is executing the script
resource "aws_iam_role" "ecs_task_role" {
  name               = "twingate-${twingate_connector.this.name}-${local.aws.region}-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_policy.json
  tags               = var.tags
}
