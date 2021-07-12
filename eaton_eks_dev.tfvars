cluster_name ="eaton_dev_eks_cluster"
cluster_log_retention_in_days=90
//copy the tags that we are using currently
tags= "name"
//provide.............
cluster_log_kms_key_id="provide"
cluster_version="1.14"
subnets=""
cluster_endpoint_private_access=""
cluster_endpoint_public_access=""
cluster_endpoint_public_access_cidrs=""
cluster_service_ipv4_cidr=""
cluster_create_timeout=""
cluster_delete_timeout=""
cluster_egress_cidrs=""
cluster_endpoint_private_access_cidrs=""
cluster_endpoint_private_access_sg=""
cluster_iam_role_name="eaton-dev-eks-cluster-iam-role"
// *****************variables for node group creation ...................

create_eks =true
node_groups_defaults=["eaton"]
node_groups=["eaton_dev"]
//create one image in ECR repo and provide that URI datadog image
//change image_id sectio in workers.tf aws_launch_configuration section
datadog_image_id = ""
//provid ethe same as above
ami_id = ""

//********************** WORKERS  config

name_prefix = "eaton_"
worker_groups =[1]
worker_groups_launch_template = [1]
kubeconfig_name = "eaton_kubeconfig"
workers_egress_cidrs=""
worker_sg_ingress_from_port=""
workers_role_name="eaton-dev-workers-iam-role"

