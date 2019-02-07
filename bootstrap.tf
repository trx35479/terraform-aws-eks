# prepare the user_data for bootstraping the worker nodes

data "template_file" "bootstrap-node" {
  template = "${file("templates/node_user_data.tpl")}"

  depends_on = [
    "module.eks-cluster",
  ]

  vars {
    endpoint     = "${module.eks-cluster.eks-endpoint}"
    ca           = "${module.eks-cluster.eks-ca}"
    cluster_name = "${var.CLUSTER_NAME}"
  }
}

data "template_file" "worker-join" {
  template = "${file("templates/config_map_aws_auth.tpl")}"

  depends_on = [
    "module.eks-node-iam",
    "module.eks-nodes",
  ]

  vars {
    worker_iam_arn = "${module.eks-node-iam.arn}"
  }
}

resource "null_resource" "worker-join" {
  triggers {
    template_rendered = "${data.template_file.worker-join.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.worker-join.rendered}' > config_map_aws_auth.yaml"
  }
}
