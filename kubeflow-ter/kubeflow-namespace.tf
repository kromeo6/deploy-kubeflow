data "external" "build_kubeflow_namespace" {
  # no dependency here because it wont run during plan
  program = ["bash", "-c", <<EOT
    kustomize build manifests/common/kubeflow-namespace/base | jq -sR '{manifest: .}'
  EOT
  ]
}

resource "kubectl_manifest" "install_kubeflow_namespace" {
  # carefull with dependencies on null
  depends_on = [data.external.build_kubeflow_namespace, 
                null_resource.wait_for_cert_manager,
                null_resource.istio_crds,
                null_resource.wait_for_oauthproxy,
                null_resource.wait_for_dex]
  for_each = { for idx, obj in split("---", data.external.build_kubeflow_namespace.result.manifest) : idx => obj }
  yaml_body = each.value
}
