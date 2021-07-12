/*
resource "local_file" "kubeconfig" {
  content              = local.kubeconfig
  filename             = substr(var.kubeconfig_output_path, -1, 1) == "/" ? "${var.kubeconfig_output_path}kubeconfig_${var.cluster_name}" : var.kubeconfig_output_path
  file_permission      = var.kubeconfig_file_permission
  directory_permission = "0755"
}
*/
