variable "azure_subscription_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "common_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "application_subnet" {
  type = list(string)
}
variable "database_subnet" {
  type = list(string)
}

variable "vnet_lzB" {
  type = string
}
