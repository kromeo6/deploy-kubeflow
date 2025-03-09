# resource "null_resource" "knative_gateway_manifests" {
#   provisioner "local-exec" {
#     command = <<EOT
#       kustomize build manifests/common/knative/knative-serving/overlays/gateways | kubectl apply -f -;
#     EOT
#   }

resource "null_resource" "knative_gateway_manifests" {
  provisioner "local-exec" {
    command = <<EOT
      kustomize build manifests/common/knative/knative-serving/overlays/gateways | kubectl apply -f - || true
      sleep 5
      kustomize build manifests/common/knative/knative-serving/overlays/gateways | kubectl apply -f -;
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      kubectl delete -k manifests/common/knative/knative-serving/overlays/gateways || true
    EOT   
  }
}

data "external" "build_knative_base" {
  # no dependency here because it wont run during plan
  program = ["bash", "-c", <<EOT
    kustomize build manifests/common/istio-1-24/cluster-local-gateway/base | jq -sR '{manifest: .}'
  EOT
  ]
}

resource "kubectl_manifest" "instal_knative_files2" {
  # carefull with dependencies on null
  depends_on = [null_resource.knative_gateway_manifests, data.external.build_knative_base]
  for_each = { for idx, obj in split("---", data.external.build_knative_base.result.manifest) : idx => obj }
  yaml_body = each.value
}

