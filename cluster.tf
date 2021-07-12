resource "aws_cloudwatch_log_group" "eks-cluster" {

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days
  kms_key_id        = var.cluster_log_kms_key_id
  tags              = var.tags
}

resource "aws_eks_cluster" "eks-cluster" {
  name                      = var.cluster_name
  enabled_cluster_log_types = var.cluster_enabled_log_types
  role_arn                  = local.cluster_iam_role_arn
  version                   = var.cluster_version
  tags                      = var.tags
  vpc_config {
    security_group_ids      = compact([local.cluster_security_group_id])
    subnet_ids              = var.subnets
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
  }
  kubernetes_network_config {
    service_ipv4_cidr = var.cluster_service_ipv4_cidr
  }
  timeouts {
    create = var.cluster_create_timeout
    delete = var.cluster_delete_timeout
  }
  depends_on = [
    aws_security_group_rule.cluster_egress_internet,
    aws_security_group_rule.cluster_https_worker_ingress,
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy,
    aws_cloudwatch_log_group.eks-cluster
  ]
}

resource "aws_security_group" "cluster" {
  name_prefix = var.cluster_name
  description = "EKS cluster security group."
  vpc_id      = var.vpc_id
  tags = merge(
    var.tags,
    {
      "Name" = "${var.cluster_name}_sg"
    },
  )
}

resource "aws_security_group_rule" "cluster_egress_internet" {
  description       = "Allow cluster egress access to the Internet."
  protocol          = "-1"
  security_group_id = local.cluster_security_group_id
  cidr_blocks       = var.cluster_egress_cidrs
  from_port         = 0
  to_port           = 0
  type              = "egress"
}

resource "aws_security_group_rule" "cluster_https_worker_ingress" {
  description              = "Allow pods to communicate with the EKS cluster API."
  protocol                 = "tcp"
  security_group_id        = local.cluster_security_group_id
  source_security_group_id = local.worker_security_group_id
  from_port                = 443
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_private_access_cidrs_source" {
//  count       = var.create_eks && var.cluster_create_endpoint_private_access_sg_rule && var.cluster_endpoint_private_access && var.cluster_endpoint_private_access_cidrs != null ? 1 : 0
  description = "Allow private K8S API ingress from custom CIDR source."
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.cluster_endpoint_private_access_cidrs

  security_group_id = aws_eks_cluster.eks-cluster.vpc_config.cluster_security_group_id
}
//create after cluster got cretaed with whiteliting the traffic tocluster(cluster ip range in sg) then uncomment line 97 in data.tf where it is refereed
/*resource "aws_security_group_rule" "cluster_private_access_sg_source" {
 // count                    = var.create_eks && var.cluster_create_endpoint_private_access_sg_rule && var.cluster_endpoint_private_access && var.cluster_endpoint_private_access_sg != null ? length(var.cluster_endpoint_private_access_sg) : 0
  description              = "Allow private K8S API ingress from custom Security Groups source."
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = var.cluster_endpoint_private_access_sg
  security_group_id = aws_eks_cluster.eks-cluster.vpc_config.cluster_security_group_id
}*/

resource "aws_iam_role" "cluster" {
  name                  = var.cluster_iam_role_name
  assume_role_policy    = data.aws_iam_policy_document.cluster_assume_role_policy.json
  //permissions_boundary  = var.permissions_boundary
 // path                  = var.iam_path
  force_detach_policies = true
  tags                  = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSClusterPolicy"
  role       = local.cluster_iam_role_name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSServicePolicy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSServicePolicy"
  role       = local.cluster_iam_role_name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceControllerPolicy" {
  policy_arn = "${local.policy_arn_prefix}/AmazonEKSVPCResourceController"
  role       = local.cluster_iam_role_name
}

/*
 Adding a policy to cluster IAM role that allow permissions
 required to create AWSServiceRoleForElasticLoadBalancing service-linked role by EKS during ELB provisioning
*/

data "aws_iam_policy_document" "cluster_elb_sl_role_creation" {
  
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeAddresses"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cluster_elb_sl_role_creation" {
  name_prefix = "${var.cluster_name}-elb-sl-role-creation"
  description = "Permissions for EKS to create AWSServiceRoleForElasticLoadBalancing service-linked role"
  policy      = data.aws_iam_policy_document.cluster_elb_sl_role_creation.json
 // path        = var.iam_path
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_elb_sl_role_creation" {
  policy_arn = aws_iam_policy.cluster_elb_sl_role_creation.arn
  role       = local.cluster_iam_role_name
}
