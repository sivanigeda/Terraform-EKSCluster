resource "aws_launch_template" "workers_launch_template" {
  name_prefix = var.name_prefix
  update_default_version = lookup(
  var.worker_groups_launch_template[0],
  "update_default_version",
  local.workers_group_defaults["update_default_version"],
  )
  network_interfaces {
    associate_public_ip_address = lookup(
    var.worker_groups_launch_template[0],
    "public_ip",
    local.workers_group_defaults["public_ip"],
    )
    delete_on_termination = lookup(
    var.worker_groups_launch_template[0],
    "eni_delete",
    local.workers_group_defaults["eni_delete"],
    )
    security_groups = flatten([
      local.worker_security_group_id,
      var.worker_additional_security_group_ids,
      lookup(
      var.worker_groups_launch_template[0],
      "additional_security_group_ids",
      local.workers_group_defaults["additional_security_group_ids"],
      ),
    ])
  }
  iam_instance_profile {
    name = coalescelist(
    aws_iam_instance_profile.workers.*.name,
    data.aws_iam_instance_profile.custom_worker_group_launch_template_iam_instance_profile.*.name)
  }
  //provide the image_id
  image_id = ""
  instance_type = "t3.medium"

  user_data = base64encode(
  local.launch_template_userdata_rendered)
  lifecycle {
    create_before_destroy = true
  }
  # Prevent premature access of security group roles and policies by pods that
  # require permissions on create/destroy that depend on workers.
  depends_on = [
    aws_security_group_rule.workers_egress_internet,
    aws_security_group_rule.workers_ingress_self,
    aws_security_group_rule.workers_ingress_cluster,
    aws_security_group_rule.workers_ingress_cluster_kubelet,
    aws_security_group_rule.workers_ingress_cluster_https,
    aws_security_group_rule.workers_ingress_cluster_primary,
    aws_security_group_rule.cluster_primary_ingress_workers,
    aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly
    //aws_iam_role_policy_attachment.workers_additional_policies
  ]
}

# Worker Groups using Launch Templates

resource "aws_autoscaling_group" "workers_launch_template" {

  name_prefix = var.name_prefix
  desired_capacity = 2
  max_size = 3
  min_size = 1
  force_delete = true
  target_group_arns = lookup(
    var.worker_groups_launch_template[0],
    "target_group_arns",
    local.workers_group_defaults["target_group_arns"]
  )
  load_balancers = lookup(
    var.worker_groups_launch_template[0],
    "load_balancers",
    local.workers_group_defaults["load_balancers"]
  )
  service_linked_role_arn = lookup(
    var.worker_groups_launch_template[0],
    "service_linked_role_arn",
    local.workers_group_defaults["service_linked_role_arn"],
  )
  vpc_zone_identifier = lookup(
    var.worker_groups_launch_template[0],
    "subnets",
    local.workers_group_defaults["subnets"]
  )
  protect_from_scale_in = lookup(
    var.worker_groups_launch_template[0],
    "protect_from_scale_in",
    local.workers_group_defaults["protect_from_scale_in"],
  )
  suspended_processes = lookup(
    var.worker_groups_launch_template[0],
    "suspended_processes",
    local.workers_group_defaults["suspended_processes"]
  )
  enabled_metrics = lookup(
    var.worker_groups_launch_template[0],
    "enabled_metrics",
    local.workers_group_defaults["enabled_metrics"]
  )
  placement_group = lookup(
    var.worker_groups_launch_template[0],
    "placement_group",
    local.workers_group_defaults["placement_group"],
  )
  termination_policies = lookup(
    var.worker_groups_launch_template[0],
    "termination_policies",
    local.workers_group_defaults["termination_policies"]
  )
  max_instance_lifetime = lookup(
    var.worker_groups_launch_template[0],
    "max_instance_lifetime",
    local.workers_group_defaults["max_instance_lifetime"],
  )
  default_cooldown = lookup(
    var.worker_groups_launch_template[0],
    "default_cooldown",
    local.workers_group_defaults["default_cooldown"]
  )
  health_check_type = lookup(
    var.worker_groups_launch_template[0],
    "health_check_type",
    local.workers_group_defaults["health_check_type"]
  )
  health_check_grace_period = lookup(
    var.worker_groups_launch_template[0],
    "health_check_grace_period",
    local.workers_group_defaults["health_check_grace_period"]
  )
  capacity_rebalance = lookup(
    var.worker_groups_launch_template[0],
    "capacity_rebalance",
    local.workers_group_defaults["capacity_rebalance"]
  )
 /* launch_template {
    launch_template_specification = {
      launch_template_id = aws_launch_template.workers_launch_template.id
      version ="1.14"
    }
  }*/
}

/*  dynamic "launch_template" {
    iterator = item
    for_each = (lookup(var.worker_groups_launch_template[0], "override_instance_types", null) != null) || (lookup(var.worker_groups_launch_template[0], "on_demand_allocation_strategy", local.workers_group_defaults["on_demand_allocation_strategy"]) != null) ? [] : [var.worker_groups_launch_template[0]]

    content {
      id = aws_launch_template.workers_launch_template.*.id[count.index]
      version = lookup(
        var.worker_groups_launch_template[0],
        "launch_template_version",
        lookup(
          var.worker_groups_launch_template[0],
          "launch_template_version",
          local.workers_group_defaults["launch_template_version"]
        ) == "$Latest"
        ? aws_launch_template.workers_launch_template.latest_version[count.index]
        : aws_launch_template.workers_launch_template.default_version[count.index]
      )
    }
  }*/

/*  dynamic "initial_lifecycle_hook" {
    for_each = var.worker_create_initial_lifecycle_hooks ? lookup(var.worker_groups_launch_template[0], "asg_initial_lifecycle_hooks", local.workers_group_defaults["asg_initial_lifecycle_hooks"]) : []
    content {
      name                    = initial_lifecycle_hook.value["name"]
      lifecycle_transition    = initial_lifecycle_hook.value["lifecycle_transition"]
      notification_metadata   = lookup(initial_lifecycle_hook.value, "notification_metadata", null)
      heartbeat_timeout       = lookup(initial_lifecycle_hook.value, "heartbeat_timeout", null)
      notification_target_arn = lookup(initial_lifecycle_hook.value, "notification_target_arn", null)
      role_arn                = lookup(initial_lifecycle_hook.value, "role_arn", null)
      default_result          = lookup(initial_lifecycle_hook.value, "default_result", null)
    }
  }*/
/*
  dynamic "warm_pool" {
    for_each = lookup(var.worker_groups_launch_template[0], "warm_pool", null) != null ? [lookup(var.worker_groups_launch_template[0], "warm_pool")] : []

    content {
      pool_state                  = lookup(warm_pool.value, "pool_state", null)
      min_size                    = lookup(warm_pool.value, "min_size", null)
      max_group_prepared_capacity = lookup(warm_pool.value, "max_group_prepared_capacity", null)
    }
  }*/

/*  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}*/


resource "aws_iam_instance_profile" "workers_launch_template" {
  name_prefix = var.name_prefix
  role = lookup(
    var.worker_groups_launch_template[0],
    "iamrole_id",
    local.default_iam_role_id,
  )
  path = var.iam_path
  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}
