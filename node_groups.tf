module "node_groups" {
  source                               = "./modules/node_groups"
  create_eks                           = var.create_eks
  cluster_name                         = aws_eks_cluster.eks-cluster.name
  default_iam_role_arn                 = aws_iam_role.workers.arn
  workers_group_defaults               = local.workers_group_defaults
  worker_security_group_id             = local.worker_security_group_id
  //worker_additional_security_group_ids = var.worker_additional_security_group_ids
  tags                                 = var.tags
  node_groups_defaults                 = var.node_groups_defaults
  node_groups                          = var.node_groups

  # Hack to ensure ordering of resource creation.
  # This is a homemade `depends_on` https://discuss.hashicorp.com/t/tips-howto-implement-module-depends-on-emulation/2305/2
  # Do not create node_groups before other resources are ready and removes race conditions
  # Ensure these resources are created before "unlocking" the data source.
  # Will be removed in Terraform 0.13
  ng_depends_on = [
    aws_eks_cluster.eks-cluster,
    aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly
  ]
}
