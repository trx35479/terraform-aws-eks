# get the eks config and append it to ~.kube/config

data "template_file" "kubeconfig" {
  template = "${file("templates/kubeconfig.tpl")}"

  depends_on = [
    "module.eks-cluster",
  ]

  vars {
    endpoint     = "${module.eks-cluster.eks-endpoint}"
    ca           = "${module.eks-cluster.eks-ca}"
    cluster_name = "${var.CLUSTER_NAME}"
  }
}

resource "null_resource" "trigger" {
  triggers {
    template_rendered = "${data.template_file.kubeconfig.rendered}"
  }

  provisioner "local-exec" {
    command = "echo '${data.template_file.kubeconfig.rendered}' > ~/.kube/config"
  }
}
