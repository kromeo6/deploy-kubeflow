# data "external" "build_kubeflow_apps" {
#   # no dependency here because it wont run during plan
#   program = ["bash", "-c", <<EOT
#     kustomize build kubeflow-app-deploy | tee ${path.module}/junk/kubeflow-apps.yaml | jq -sR '{manifest: .}'
#   EOT
#   ]
# }

# data "kubectl_path_documents" "read_kubeflow_apps" {
#   depends_on = [data.external.build_kubeflow_apps]
#   pattern    = "${path.module}/junk/kubeflow-apps.yaml"
# }

# resource "kubectl_manifest" "install_kubeflow_apps" {
#   depends_on = [data.kubectl_path_documents.read_kubeflow_apps]

#   # for_each = { for idx, obj in split("---", data.external.build_certs-issuer-manifests.result.manifest) : idx => obj }
#   for_each = toset(data.kubectl_path_documents.read_kubeflow_apps.documents)

#   yaml_body = each.value
# }




resource "null_resource" "kubeflow_apps" {
  provisioner "local-exec" {
    command = <<EOT
      while ! kustomize build kubeflow-app-deploy | kubectl apply --server-side --force-conflicts -f -; do echo "Retrying to apply app resources"; sleep 20; done
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -k kubeflow-app-deploy || true"
  }
}