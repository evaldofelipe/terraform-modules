# Subnet definition

variable "env" {
  description = "Environment to orchestrate. This name will be use with a prefix for resource group, subnet, nsg, route table names"
  default = "test"
}

variable "location" {
  description = "The location/region where the subnet will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  default = "eastus2"
}

variable "vnet_address_space" {
  description = "A list of address space that will be used by the virtual network."
  type = "list"
  default = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  description = "The address prefix to use for the public subnet."
  default = "10.0.1.0/24"
}

# Security group rules arguments
# [priority, direction, access, protocol, source_port_range, source_address_prefix, destination_port_range, destination_address_prefix, description]"
# All the fields are required.
variable "security_group_rules" {
  description = "Security rules for the network security group using this format name = [priority, direction, access, protocol, source_port_range, source_address_prefix, destination_port_range, destination_address_prefix, description]"
  type = "list"
  default = []
}

# Route table routes arguments
# [name, address_prefix, next_hop_type, next_hop_in_ip_address]"
# All the fields are required excepted next_hop_in_ip_address.
variable "route_table_routes" {
  description = "Routes for the route table using this format name = [name, address_prefix, next_hop_type, next_hop_in_ip_address]"
  type = "list"
  default = []
}

variable "bastion_platform_fault_domain_count" {
  description = "number of update domains to bastion virtual machines"
  default = "1"
}

variable "bastion_platform_update_domain_count" {
  description = "number of fault domains to bastion virtual machines"
  default = "1"
}

variable "bastion_private_ip_address" {
  description = "private ip address to bastion instance"
}

variable "bastion_virtual_machine_disk_size" {
  description = "disk size to bastion virtual machine"
  default = "31"
}

variable "bastion_virtual_machine_instance_size" {
  description = "instance size to bastion virtual machine"
  default = "Standard_DS2_v2"
}

variable "bastion_image_publisher" {
  description = "publisher image to bastion virtual machine"
  default = "Canonical"
}

variable "bastion_image_offer" {
  description = "offer image to bastion virtual machine"
  default = "UbuntuServer"
}

variable "bastion_image_sku" {
  description = "sku image to bastion virtual machine"
  default = "16.04-LTS"
}

variable "bastion_image_version" {
  description = "version image to bastion virtual machine"
  default = "latest"
}

variable "bastion_admin_username" {
  description = "name of the administrator account"
  default = "bootstrap"
}

variable "bastion_public_ssh_key" {
  description = "public ssh key to bastion virtual machine"
}

