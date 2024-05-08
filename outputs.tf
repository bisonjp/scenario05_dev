output "admin_password" {
  sensitive = true
  value     = random_password.password.result
}

output "tls_private_key" { 
    value = tls_private_key.key.private_key_pem 
    sensitive = true
}