# prepare the user_data for bootstraping the worker nodes

data "template_file" "bootstrap-node" {
  template = file("templates/node_user_data.tpl")

  vars = {
    endpoint     = module.eks-cluster.eks-endpoint
    ca           = module.eks-cluster.eks-ca
    cluster_name = var.cluster_name
  }
}

data "template_file" "worker-join" {
  template = file("templates/config_map_aws_auth.tpl")

  vars = {
    worker_iam_arn = module.eks-node-iam.arn
  }
}

resource "null_resource" "worker-join" {
  triggers = {
    template_rendered = data.template_file.worker-join.id
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.worker-join.rendered}' > $(pwd)/config_map_aws_auth.yaml"
  }
}
