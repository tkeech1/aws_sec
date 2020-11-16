resource "null_resource" "frontend_var_replacement" {
  provisioner "local-exec" {
    command = "python mwa/s3deploy/frontend_jinja.py"
  }
}

resource "null_resource" "print_web_endpoint" {
  provisioner "local-exec" {
    command = "echo ${var.website_endpoint} >> web_url.txt"
  }
}
