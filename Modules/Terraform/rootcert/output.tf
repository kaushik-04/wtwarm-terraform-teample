# #############################################################################
# # OUTPUTS ADO rivate Endpoint
# #############################################################################

output "null_resource" {
  description = "output of the null resource"
  value       = null_resource.create_cert
}
