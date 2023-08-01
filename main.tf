locals {
  name = coalesce(var.name, module.this.name, "eip-manager-${random_string.eip_manager_random_suffix.result}")
}

# ============================================================== eip-manager ===

module "eip_manager_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name    = local.name
  context = module.this.context
}

# only appliable if name variable was not set
resource "random_string" "eip_manager_random_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ------------------------------------------------------------------- lambda ---

resource "aws_lambda_function" "this" {
  count = module.this.enabled ? 1 : 0

  function_name = module.eip_manager_label.id
  filename      = module.source_code[0].artifact_package_path
  handler       = "eip_manager.handler"
  runtime       = "python3.8"
  timeout       = 600
  role          = aws_iam_role.this[0].arn
  layers        = []

  environment {
    variables = {
      LOG_LEVEL       = "INFO"
      POOL_TAG_KEY    = var.pool_tag_key
      POOL_TAG_VALUES = join(",", var.pool_tag_values)
    }
  }

  tags = module.eip_manager_label.tags

  depends_on = [
    module.source_code
  ]
}

resource "aws_lambda_permission" "this" {
  count = module.this.enabled ? 1 : 0

  statement_id  = "allow-cwevents"
  function_name = aws_lambda_function.this[0].function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
}

module "source_code" {
  source  = "cruxstack/artifact-packager/docker"
  version = "1.3.2"
  count   = module.this.enabled ? 1 : 0

  artifact_src_path      = "/tmp/package.zip"
  artifact_dst_directory = "${path.module}/dist"
  docker_build_context   = abspath("${path.module}/assets/eip-manager")
  docker_build_target    = "package"

  context = module.eip_manager_label.context
}

# ------------------------------------------------------------ subscriptions ---

resource "random_string" "sync_unique_id" {
  length  = 6
  special = false
  lower   = false
  upper   = true

  keepers = {
    id = module.this.id
  }
}

module "periodic_sync_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  id_length_limit = 64
  attributes      = ["periodic-sync", random_string.sync_unique_id.id]
  label_order     = ["name", "attributes"]
  context         = module.eip_manager_label.context
}

resource "aws_cloudwatch_event_rule" "periodic_sync" {
  count = module.this.enabled ? 1 : 0

  name                = module.periodic_sync_label.id
  description         = "Rule to trigger the EIP manager Lambda function every 5 minutes for periodic EIP synchronization."
  schedule_expression = "rate(5 minutes)"

  tags = module.periodic_sync_label.tags
}

resource "aws_cloudwatch_event_target" "periodic_sync" {
  count = module.this.enabled ? 1 : 0

  target_id = module.periodic_sync_label.id
  rule      = aws_cloudwatch_event_rule.periodic_sync[0].name
  arn       = aws_lambda_function.this[0].arn
}

module "triggered_sync_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  id_length_limit = 64
  attributes      = ["triggered-sync", random_string.sync_unique_id.id]
  label_order     = ["name", "attributes"]
  context         = module.eip_manager_label.context
}

resource "aws_cloudwatch_event_rule" "triggered_sync" {
  count = module.this.enabled ? 1 : 0

  name        = module.triggered_sync_label.id
  description = "Rule to trigger the EIP manager Lambda function whenever there's a state change notification for EC2 instances. This ensures EIPs are quickly re-assigned when instances are stopped or terminated."

  event_pattern = jsonencode({
    "source"      = ["aws.ec2"],
    "detail-type" = ["EC2 Instance State-change Notification"]
  })

  tags = module.triggered_sync_label.tags
}

resource "aws_cloudwatch_event_target" "triggered_sync" {
  count = module.this.enabled ? 1 : 0

  target_id = module.triggered_sync_label.id
  rule      = aws_cloudwatch_event_rule.triggered_sync[0].name
  arn       = aws_lambda_function.this[0].arn
}

# ---------------------------------------------------------------------- iam ---

resource "aws_iam_role" "this" {
  count = module.this.enabled ? 1 : 0

  name        = module.eip_manager_label.id
  description = ""

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow"
      Principal = { "Service" : "lambda.amazonaws.com" }
      Action    = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]

  inline_policy {
    name   = "access"
    policy = data.aws_iam_policy_document.this[0].json
  }

  tags = module.eip_manager_label.tags
}

data "aws_iam_policy_document" "this" {
  count = module.this.enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "tag:GetTagValues"
    ]
    resources = [
      "*",
    ]
  }
}
