data "external" "build_kubeflow_apps" {
  # no dependency here because it wont run during plan
  program = ["bash", "-c", <<EOT
    kustomize build manifests/common/istio-1-24/kubeflow-istio-resources/base | jq -sR '{manifest: .}'
  EOT
  ]
}

resource "kubectl_manifest" "install_kubeflow_istio_resources" {
  # carefull with dependencies on null
  depends_on = [data.external.build_kubeflow_istio_resources, resource.kubectl_manifest.install_kubeflow_namespace]
  for_each = { for idx, obj in split("---", data.external.build_kubeflow_istio_resources.result.manifest) : idx => obj }
  yaml_body = each.value
}
