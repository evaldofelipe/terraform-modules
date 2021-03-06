provider "azurerm" {
  version = "~> 1.9.0"
}

resource "azurerm_subnet" "subnet" {
  name                      = "${var.subnet_name}"
  virtual_network_name      = "${var.vnet_name}"
  resource_group_name       = "${var.vnet_resource_group}"
  address_prefix            = "${var.subnet_address_prefix}"
  network_security_group_id = "${module.nsg.network_security_group_id}"
  route_table_id            = "${module.route_table.route_table_id}"
}

module "nsg" {
  source              = "../nsg"
  vnet_resource_group = "${var.vnet_resource_group}"
  location            = "${var.location}"
  security_group_name = "${var.security_group_name}"
  rules               = "${var.security_group_rules}"
}

module "route_table" {
  source              = "../route-table"
  vnet_resource_group = "${var.vnet_resource_group}"
  location            = "${var.location}"
  route_table_name    = "${var.route_table_name}"
  routes              = "${var.route_table_routes}"
}
