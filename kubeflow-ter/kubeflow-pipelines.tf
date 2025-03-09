resource "null_resource" "kubeflow_pipelines" {
    depends_on = [resource.kubectl_manifest.install_kubeflow_namespace]
  provisioner "local-exec" {
    command = <<EOT
      while ! kustomize build manifests/apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user | kubectl apply --server-side --force-conflicts -f -; do echo "Retrying to apply kubeflow pipelines resources"; sleep 20; done
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete -k manifests/apps/pipeline/upstream/env/cert-manager/platform-agnostic-multi-user || true"
  }
}

# maybe change in fut