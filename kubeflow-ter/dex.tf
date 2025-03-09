
data "external" "build_dex_manifests" {
  # no dependency here because it wont run during plan
  program = ["bash", "-c", <<EOT
    kustomize build manifests/common/dex/overlays/oauth2-proxy | jq -sR '{manifest: .}'
  EOT
  ]
}

resource "kubectl_manifest" "inssstal_dex_files" {
  # carefull with dependencies on null
  depends_on = [data.external.build_dex_manifests]
  for_each = { for idx, obj in split("---", data.external.build_dex_manifests.result.manifest) : idx => obj }
  yaml_body = each.value
}

resource "null_resource" "wait_for_dex" {
  depends_on = [kubectl_manifest.inssstal_dex_files]

  provisioner "local-exec" {
    command = <<EOT
      kubectl wait --for=condition=ready pods --all --timeout=180s -n auth
    EOT
  }
}