output "app_url" {
  value = "http://${local.app_host}"
}

output "argocd_url" {
  value = "https://${local.argocd_host}"
}

output "load_balancer_hostname" {
  value = data.kubernetes_service_v1.ingress.status[0].load_balancer[0].ingress[0].hostname
}

output "name_servers" {
  description = "Delegate the domain to these NS in your domain registrar panel."
  value       = local.dns.name_servers
}
