variable "ip_addresses" {
  default = [
    "10.0.2.11",
    "10.0.2.12",
    "10.0.2.13",
  ]
}

variable "vm_count" {
    type = "string"
    default = 10
}


variable "resource_group"  { default = "demo-rg" }
variable "location"        { default = "southcentralus" }
variable "image_publisher" { default = "Canonical" }
variable "image_offer"     { default = "UbuntuServer" }
variable "image_sku"       { default = "16.04-LTS" }
variable "image_version"   { default = "latest" }
variable "vm_size"         { default = "Standard_A0" }
variable "admin_username"  { default = "adminuser" }
variable "admin_password"  { default = "EXI??weu209ew29" }

resource "azurerm_resource_group" "test" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "test" {
  name                = "test"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.test.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "test" {
  name  = "nic${count.index}"
  count = "${var.vm_count}"

  location            = "${azurerm_resource_group.test.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${element(var.ip_addresses, count.index)}"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name = "vm${count.index}"
  count = "${var.vm_count}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.test.name}"
  vm_size             = "${var.vm_size}"

  network_interface_ids = ["${element(azurerm_network_interface.test.*.id, count.index)}"]
  delete_os_disk_on_termination = "true"

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }


  storage_os_disk {
    name              = "vm${count.index}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "vm${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

