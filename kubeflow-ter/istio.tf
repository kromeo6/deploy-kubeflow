resource "null_resource" "istio_crds" {
  provisioner "local-exec" {
    command = <<EOT
      kustomize build manifests/common/istio-1-24/istio-crds/base | kubectl apply -f -
      kustomize build manifests/common/istio-1-24/istio-namespace/base | kubectl apply -f -
      kustomize build overlays/dev/istio/part1 | kubectl apply -f -
    EOT
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOT
      kubectl delete -k overlays/dev/istio/part1
      kubectl delete -k manifests/common/istio-1-24/istio-namespace/base
      kubectl delete -k manifests/common/istio-1-24/istio-crds/base
    EOT
  }
}

data "external" "build_istio-manifests" {
  # no dependency here because it wont run during plan
  program = ["bash", "-c", <<EOT
    kustomize build overlays/dev/istio/part2 | jq -sR '{manifest: .}'
  EOT
  ]
}

resource "kubectl_manifest" "inssstal_istio_files" {
  # carefull with dependencies on null
  depends_on = [null_resource.istio_crds, null_resource.cert_manager_issuer]
  for_each = { for idx, obj in split("---", data.external.build_istio-manifests.result.manifest) : idx => obj }
  yaml_body = each.value
}

resource "null_resource" "wait_for_istio_crds" {
  depends_on = [kubectl_manifest.inssstal_istio_files]

  provisioner "local-exec" {
    command = <<EOT
      echo "Waiting for all Istio Pods to become ready..."
      kubectl wait --for=condition=Ready pods --all -n istio-system --timeout 300s
    EOT
  }
}

# way to instal #2 - install crd with null and everithin else with kubectl_manifests 
# and sortoptions as in examples