resource "null_resource" "create_cert" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "bash ./create_and_import_root_certs_into_kv.sh ${var.subscription_id} ${var.client_id} ${var.client_secret} ${var.tenant_id} ${var.root_cert_name} ${var.keyvault_name} ${var.root_cert_passphrase} ./${var.policy_path}"
  }
}