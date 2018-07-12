provider "azurerm" {
  version = "~> 1.8"
}

provider "random" {
  version = "~> 1.0"
}

module "os" {
  source       = "./os"
  vm_os_simple = "${var.vm_os_simple}"
}

resource "random_id" "vm-sa" {
  count = "${var.nb_instances > 0 ? "1" : "0"}"

  keepers = {
    vm_hostname = "${var.vm_hostname}"
  }

  byte_length = 6
}

resource "azurerm_storage_account" "vm-sa" {
  count                    = "${var.boot_diagnostics == "true" ? 1 : 0}"
  name                     = "bootdiag${lower(random_id.vm-sa.hex)}"
  resource_group_name      = "${var.resource_group_name}"
  location                 = "${var.location}"
  account_tier             = "${element(split("_", var.boot_diagnostics_sa_type),0)}"
  account_replication_type = "${element(split("_", var.boot_diagnostics_sa_type),1)}"
  tags                     = "${var.tags}"
}

resource "azurerm_virtual_machine" "vm-linux" {
  count                         = "${var.nb_instances}"
  name                          = "${var.vm_hostname}-vm-${count.index}"
  location                      = "${var.location}"
  resource_group_name           = "${var.resource_group_name}"
  availability_set_id           = "${azurerm_availability_set.vm.id}"
  vm_size                       = "${var.vm_size}"
  network_interface_ids         = ["${element(azurerm_network_interface.vm.*.id, count.index)}"]
  delete_os_disk_on_termination = "${var.delete_os_disk_on_termination}"

  storage_image_reference {
    id        = "${var.vm_os_id}"
    publisher = "${var.vm_os_id == "" ? coalesce(var.vm_os_publisher, module.os.calculated_value_os_publisher) : ""}"
    offer     = "${var.vm_os_id == "" ? coalesce(var.vm_os_offer, module.os.calculated_value_os_offer) : ""}"
    sku       = "${var.vm_os_id == "" ? coalesce(var.vm_os_sku, module.os.calculated_value_os_sku) : ""}"
    version   = "${var.vm_os_id == "" ? var.vm_os_version : ""}"
  }

  storage_os_disk {
    name              = "${var.vm_hostname}-vm-${count.index}-osdisk"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "${var.os_managed_disk_type}"
  }

  os_profile {
    computer_name  = "${var.vm_hostname}-${count.index}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_key}")}"
    }
  }

  tags = "${var.tags}"

  boot_diagnostics {
    enabled     = "${var.boot_diagnostics}"
    storage_uri = "${var.boot_diagnostics == "true" ? join(",", azurerm_storage_account.vm-sa.*.primary_blob_endpoint) : "" }"
  }
}

resource "azurerm_availability_set" "vm" {
  count                        = "${var.nb_instances > 0 ? "1" : "0"}"
  name                         = "${var.vm_hostname}-availset"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  platform_update_domain_count = "${var.avset_update_domain_count}"
  platform_fault_domain_count  = "${var.avset_fault_domain_count}"
  managed                      = true
}

resource "azurerm_public_ip" "vm" {
  count                        = "${var.enable_public_ip == "true" ? var.nb_instances : 0}"
  name                         = "${var.vm_hostname}-public-ip-${count.index}"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "${var.public_ip_address_allocation}"
  domain_name_label            = "${element(var.public_ip_dns_list, count.index)}"
}

resource "azurerm_network_interface" "vm" {
  count                = "${var.nb_instances}"
  name                 = "${var.vm_hostname}-nic-${count.index}"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  enable_ip_forwarding = "${var.enable_ip_forwarding}"

  ip_configuration {
    name                          = "default-ip-config"
    subnet_id                     = "${var.subnet_id}"
    private_ip_address_allocation = "${var.private_ip_address_allocation}"
    private_ip_address            = "${var.private_ip_address_allocation == "static" ? element(var.private_ip_address_list,count.index) : "" }"
    public_ip_address_id          = "${length(azurerm_public_ip.vm.*.id) > 0 ? element(concat(azurerm_public_ip.vm.*.id, list("")), count.index) : ""}"
  }
}

resource "azurerm_managed_disk" "vm" {
  count                = "${var.data_disk == "true" ? var.nb_instances : 0}"
  name                 = "${var.vm_hostname}-vm-${count.index}-datadisk"
  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  storage_account_type = "${var.data_managed_disk_type}"
  create_option        = "Empty"
  disk_size_gb         = "${var.data_disk_size_gb}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm" {
  count                = "${var.data_disk == "true" ? var.nb_instances : 0}"
  managed_disk_id    = "${element(azurerm_managed_disk.vm.*.id, count.index)}"
  virtual_machine_id = "${element(azurerm_virtual_machine.vm-linux.*.id, count.index)}"
  lun                = "0"
  caching            = "${var.data_disk_caching}"
}

