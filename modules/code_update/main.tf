resource "null_resource" "frontend_var_replacement" {
  provisioner "local-exec" {
    command = "python ./code/code_update.py --api-endpoint-dns-name=${var.api_endpoint_dns_name}"
  }
}
