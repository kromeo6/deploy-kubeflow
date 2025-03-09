# resource "null_resource" "kserve_crd" {
#     depends_on = [resource.kubectl_manifest.install_kubeflow_namespace]
#   provisioner "local-exec" {
#     command = <<EOT
#       kustomize build manifests/apps/kserve/kserve | kubectl apply --server-side --force-conflicts -f -
#     EOT
#   }

#   provisioner "local-exec" {
#     when    = destroy
#     command = "kubectl delete -k manifests/apps/kserve/kserve || true"
#   }
# }

# # maybe change in fut