resource "aws_ecs_task_definition" "task" {
  count        = var.enable_dd ? 0 : 1
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
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
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


resource "aws_ecs_task_definition" "tg_dd" {
  count        = var.enable_dd ? 1 : 0
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
      cpu = 1024
      dockerLabels = {
        "com.datadoghq.ad.logs" = "[{\"service\":\"Twingate Connection\",\"source\":\"Twingate\",\"log_processing_rules\":[{\"type\":\"include_at_match\",\"name\":\"include_only_analytics\",\"pattern\":\"^ANALYTICS\"},{\"type\":\"mask_sequences\",\"name\":\"remove_analytics_prefix\",\"replace_placeholder\":\"\",\"pattern\":\"^ANALYTICS\\\\s+\"}]}]"
      },
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
        logDriver = "awsfirelens",
        options = {
          provider   = "ecs",
          dd_service = "Twingate Connection",
          Host       = "http-intake.logs.datadoghq.com",
          TLS        = "on",
          dd_source  = "Twingate",
          dd_tags    = "env:${var.env} remote_network:${var.twingate_network}",
          Name       = "datadog"
        },
        secretOptions = [
          {
            name      = "apikey",
            valueFrom = var.datadog_api_key
          }
        ]
      },
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
    {
      essential = true,
      firelensConfiguration = {
        options = {
          "config-file-type"        = "file",
          "config-file-value"       = "/fluent-bit/configs/parse-json.conf",
          "enable-ecs-log-metadata" = "true",
        },
        type = "fluentbit"
      },
      image          = var.fluentbit_container_image,
      mountPoints    = [],
      name           = "log-router",
      portMappings   = [],
      systemControls = [],
      user           = "0",
      volumesFrom    = []
    },
    {
      environment = [
        {
          "name"  = "DD_CONTAINER_INCLUDE_LOGS",
          "value" = "name:twingate-${twingate_connector.this.name}"
        },
        {
          "name" : "DD_ECS_COLLECT_RESOURCE_TAGS_EC2",
          "value" : "true"
        },
        {
          "name" : "DD_ECS_TASK_COLLECTION_ENABLED",
          "value" : "true"
        },
        {
          "name" : "DD_CONTAINER_EXCLUDE",
          "value" : "name:datadog-agent name:log-router"
        },
        {
          "name" : "DD_SITE",
          "value" : "datadoghq.com"
        },
        {
          "name" : "DD_PROCESS_AGENT_ENABLED",
          "value" : "true"
        },
        {
          "name" : "ECS_FARGATE",
          "value" : "true"
        },
        {
          "name" : "DD_APM_ENABLED",
          "value" : "false"
        },
        {
          "name" : "DD_LOGS_ENABLED",
          "value" : "true"
        },
        {
          "name" : "DD_TAGS",
          "value" : "env:${var.env} remote_network:${var.twingate_network}"
        },
        {
          "name" : "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL",
          "value" : "true"
        },
        {
          "name" : "DD_DOGSTATSD_NON_LOCAL_TRAFFIC",
          "value" : "true"
        }
      ],
      essential = false,
      image     = var.datadog_container_image,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = data.aws_cloudwatch_log_group.this.name,
          mode                  = "non-blocking",
          max-buffer-size       = "25m",
          awslogs-region        = local.aws.region,
          awslogs-stream-prefix = "/ecs/twingate/${twingate_connector.this.name}/dd"
        }
      },
      mountPoints  = [],
      name         = "datadog-agent",
      portMappings = [],
      secrets = [
        {
          name      = "DD_API_KEY",
          valueFrom = var.datadog_api_key
        }
      ],
      systemControls = [],
      volumesFrom    = []
    }
  ])
  tags       = var.tags
  depends_on = [twingate_connector.this, aws_secretsmanager_secret_version.this]
}

