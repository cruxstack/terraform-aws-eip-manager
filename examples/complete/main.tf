locals {
  name = coalesce(var.name, module.this.name, "tfexample-eip-manager-${random_string.example_random_suffix.result}")
  tags = { tf_module = "cruxstack/eip-manager/aws", tf_module_example = "complete" }

  user_data = {
    web_server = <<-EOF
      #!/bin/bash
      echo "Hello, World" > index.html
      nohup busybox httpd -f -p 8080 &
    EOF
    db_server  = <<-EOF
      #!/bin/bash
      # commands to start your DB server go here
    EOF
  }

  pool_tag_key = "${module.example_label.id}-pool"
}

module "example_label" {
  source  = "cloudposse/label/null"
  version = "0.25.0"

  name    = local.name
  tags    = local.tags
  context = module.this.context
}

# only appliable if name variable was not set
resource "random_string" "example_random_suffix" {
  length  = 6
  special = false
  upper   = false
}

# ============================================================== eip-manager ===

module "eip_manager" {
  source = "../.."

  pool_tag_key    = local.pool_tag_key
  pool_tag_values = ["web-servers", "db-servers"]

  context = module.example_label.context # not required
}

# --------------------------------------------------------------------- eips ---

resource "aws_eip" "public_web_eip" {
  domain = "vpc"
  tags   = { (local.pool_tag_key) = "web-servers" }
}

resource "aws_eip" "private_db_eip" {
  domain = "vpc"
  tags   = { (local.pool_tag_key) = "db-servers" }
}

# ====================================================== auto-scaling-groups ===

resource "aws_launch_template" "web_server" {
  name                   = "${module.example_label.id}-web-servers"
  image_id               = data.aws_ssm_parameter.amzn2_image_id.value
  instance_type          = "t2.micro"
  update_default_version = true
  user_data              = base64encode(local.user_data.web_server)

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [module.security_group.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web_servers" {
  name                = "${module.example_label.id}-web-servers"
  vpc_zone_identifier = var.vpc_subnet_ids
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
      spot_instance_pools                      = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.web_server.id
        version            = aws_launch_template.web_server.latest_version
      }
    }
  }

  tag {
    key                 = local.pool_tag_key
    value               = "web-servers"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = module.example_label.tags

    content {
      key                 = tag.key == "name" ? "Name" : tag.key
      value               = lower(tag.key) == "name" ? "${tag.value}-web-server" : tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [module.eip_manager]
}

resource "aws_launch_template" "db_server" {
  name                   = "${module.example_label.id}-db-servers"
  image_id               = data.aws_ssm_parameter.amzn2_image_id.value
  instance_type          = "t2.micro"
  update_default_version = true
  user_data              = base64encode(local.user_data.db_server)

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [module.security_group.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "db_servers" {
  name                = "${module.example_label.id}-db-servers"
  vpc_zone_identifier = var.vpc_subnet_ids
  desired_capacity    = 1
  max_size            = 1
  min_size            = 0

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 0
      spot_allocation_strategy                 = "capacity-optimized"
      spot_instance_pools                      = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.db_server.id
        version            = aws_launch_template.db_server.latest_version
      }
    }
  }

  tag {
    key                 = local.pool_tag_key
    value               = "db-servers"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = module.example_label.tags

    content {
      key                 = tag.key == "name" ? "Name" : tag.key
      value               = lower(tag.key) == "name" ? "${tag.value}-db-server" : tag.value
      propagate_at_launch = true
    }
  }

  depends_on = [module.eip_manager]
}

# ----------------------------------------------------------- security-group ---

module "security_group" {
  source  = "cloudposse/security-group/aws"
  version = "2.2.0"

  create_before_destroy      = true
  preserve_security_group_id = false
  vpc_id                     = var.vpc_id
  allow_all_egress           = true

  rules_map = {
    ingress = [{
      key         = "self"
      type        = "ingress"
      from_port   = 0
      to_port     = 65535
      protocol    = "-1" # allow ping
      description = "allow all traffic within this security group"
      self        = true
    }]
  }

  context = module.example_label.context
}

# =================================================================== lookup ===

data "aws_ssm_parameter" "amzn2_image_id" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-ebs"
}
