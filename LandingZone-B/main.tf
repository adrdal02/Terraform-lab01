terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.49.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.environment}-${var.common_name}"
  location = var.location
}


resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}-${var.common_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "application" {
  name                 = "application-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = var.application_subnet
}

resource "azurerm_subnet" "database" {
  name                 = "database-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = var.database_subnet
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${var.environment}-${var.common_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "nicvm-${var.environment}-${var.common_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "test1"
    subnet_id                     = azurerm_subnet.application.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.environment}-${var.common_name}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_D2s_v3"
  admin_username      = "azureadmin"
  computer_name       = "vm-${var.environment}-${var.common_name}"
  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]
  admin_password = "Admin123"
  os_disk {
    name                 = "vm-OS-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
  disable_password_authentication = false
}

resource "azurerm_virtual_network_peering" "vnet-peering" {
  name                      = "vnet-link-b-to-a"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.vnet.name
  remote_virtual_network_id = var.vnet_lzB
  allow_forwarded_traffic   = true
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.environment}-${var.common_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_subnet_network_security_group_association" "nsg-subnet-association" {
  subnet_id                 = azurerm_subnet.application.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}