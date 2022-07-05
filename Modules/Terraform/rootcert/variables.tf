
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which Firewall needs to be created"
}
variable "root_cert_name" {
  type        = string
  description = "Enter a name for the root certificate."
}
variable "root_cert_passphrase" {
  type        = string
  description = "Enter Certificate password phrase for provisioning resources in Azure"
}
variable "keyvault_name" {
  type        = string
  description = "Enter Key Vault name for provisioning resources in Azure"
}
variable "policy_path" {
  type        = string
  description = "Path to the root certicate policy json definition for a REST Call"
}