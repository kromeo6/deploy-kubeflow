
data "external" "build_oauth2-proxy" {
  # depends_on = [null_resource.wait_for_istio_crds]
  # depends_on = [null_resource.wait_for_cert_manager] # no dependency here because it wont run during plan
  program = ["bash", "-c", <<EOT
    kustomize build manifests/common/oauth2-proxy/overlays/m2m-dex-and-kind/ | tee ${path.module}/junk/oauth2-proxy.yaml | jq -sR '{manifest: .}'
  EOT
  ]
}

data "kubectl_path_documents" "read_oauth2-proxy" {
  depends_on = [data.external.build_oauth2-proxy]
  pattern    = "${path.module}/junk/oauth2-proxy.yaml"
}

resource "kubectl_manifest" "install_oauthproxy_files" {
  depends_on = [data.kubectl_path_documents.read_oauth2-proxy, resource.kubectl_manifest.inssstal_istio_files, null_resource.wait_for_istio_crds]
  # for_each = { for idx, obj in split("---", data.external.build_oauth-proxy-manifests.result.manifest) : idx => obj }
  for_each = toset(data.kubectl_path_documents.read_oauth2-proxy.documents)
  yaml_body = each.value
}


resource "null_resource" "wait_for_oauthproxy" {
  depends_on = [kubectl_manifest.install_oauthproxy_files]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for all oauth proxy Pods to become ready..."
      kubectl wait --for=condition=ready pod -l 'app.kubernetes.io/name=oauth2-proxy' --timeout=180s -n oauth2-proxy
      kubectl wait --for=condition=ready pod -l 'app.kubernetes.io/name=cluster-jwks-proxy' --timeout=180s -n istio-system
    EOT
  }
}