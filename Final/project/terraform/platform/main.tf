resource "helm_release" "ingress" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.15.1"
  atomic           = true
  timeout          = 900

  values = [yamlencode({
    controller = {
      replicaCount = 1
      extraArgs    = { enable-ssl-passthrough = "" }
      resources = {
        requests = { cpu = "100m", memory = "128Mi" }
        limits   = { memory = "256Mi" }
      }
      service = {
        type                  = "LoadBalancer"
        externalTrafficPolicy = "Cluster"
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled" = "true"
          "service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout"           = "60"
        }
      }
    }
  })]
}

module "argocd_password" {
  source   = "../argocd-password"
  password = var.argocd_admin_password
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.13.1"
  atomic           = true
  timeout          = 900

  values = [
    file("${path.module}/values/argocd.yaml"),
    yamlencode({ global = { domain = local.argocd_host } })
  ]

  set_sensitive = [{
    name  = "configs.secret.argocdServerAdminPassword"
    value = module.argocd_password.bcrypt_hash
  }]

  depends_on = [helm_release.ingress]
}

# Helm manages the Application without requiring its CRD during terraform plan.
# Its finalizer removes the Git-managed workloads before Argo CD is uninstalled.
resource "helm_release" "application" {
  name      = "backend-application"
  namespace = "argocd"
  chart     = "${path.module}/../../argocd"
  wait      = true
  timeout   = 600

  values = [yamlencode({
    repoURL = var.repo_url
    appHost = local.app_host
  })]

  depends_on = [helm_release.argocd, kubernetes_secret_v1.repository]
}

resource "kubernetes_secret_v1" "repository" {
  count = nonsensitive(var.git_token != "") ? 1 : 0
  metadata {
    name      = "backend-git-repository"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    type     = "git"
    url      = var.repo_url
    username = "x-access-token"
    password = var.git_token
  }
  depends_on = [helm_release.argocd]
}

data "kubernetes_service_v1" "ingress" {
  metadata {
    name      = "ingress-nginx-controller"
    namespace = "ingress-nginx"
  }
  depends_on = [helm_release.ingress]
}

resource "aws_route53_record" "ingress" {
  for_each = toset([local.app_host, local.argocd_host])
  zone_id  = local.zone_id
  name     = each.value
  type     = "CNAME"
  ttl      = 60
  records  = [data.kubernetes_service_v1.ingress.status[0].load_balancer[0].ingress[0].hostname]
}
