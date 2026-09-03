resource "aws_ecs_task_definition" "this" {
  family       = "twingate-${twingate_connector.this.name}"
  cpu          = "1024"
  memory       = "2048"
  network_mode = "awsvpc"
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  skip_destroy             = true
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {
      cpu = 1024,
      environment = [
        {
          name  = "AWS_DEFAULT_REGION",
          value = local.aws.region
        },
        {
          name  = "TWINGATE_LOG_ANALYTICS",
          value = "v2"
        },
        {
          name  = "TWINGATE_LABEL_DEPLOYED_BY",
          value = "ecs"
        },
        {
          name  = "TWINGATE_NETWORK",
          value = var.twingate_network
        }
      ],
      essential = true,
      image     = var.twingate_image,
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.log_group_name
          awslogs-region        = local.aws.region
          awslogs-stream-prefix = "twingate"
          mode                  = "non-blocking"
          max-buffer-size       = "25m"
        }
      }

      memory       = 2048,
      mountPoints  = [],
      name         = "twingate-${twingate_connector.this.name}",
      portMappings = [],
      secrets = [
        {
          name      = "TWINGATE_ACCESS_TOKEN",
          valueFrom = "${aws_secretsmanager_secret.this.arn}:TWINGATE_ACCESS_TOKEN::"
        },
        {
          name      = "TWINGATE_REFRESH_TOKEN",
          valueFrom = "${aws_secretsmanager_secret.this.arn}:TWINGATE_REFRESH_TOKEN::"
        }
      ],
      systemControls = [
        {
          namespace = "net.ipv4.ping_group_range",
          value     = "0 2147483647"
        }
      ],
      volumesFrom : []
    },
  ])
  tags       = var.tags
  depends_on = [twingate_connector.this, aws_secretsmanager_secret_version.this]
}
