# Define Terraform provider
terraform {
  required_version = ">=0.12"
}

# Configure the Azure provider
provider "azurerm" {
  version = ">= 2.0.0"
  features {}
  environment     = "public"
  subscription_id = var.azure-subscription-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  tenant_id       = var.azure-tenant-id
}

#get the image that was create by the packer script
data "azurerm_image" "packer-image" {
  name                = "udacity-server-image"
  resource_group_name = var.packer_resource_group
}

#create the resource group specificed by the user
resource "azurerm_resource_group" "main" {
  name     = var.resource_group
  location = var.location
}

#create the network security group specificed 
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

#Link the Security Rules defined on locals.tf for easy understanding
resource "azurerm_network_security_rule" "mynsgrules" {
  for_each                    = local.nsgrules 
  name                        = each.key
  direction                   = each.value.direction
  access                      = each.value.access
  priority                    = each.value.priority
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_resource_group.main.name
  network_security_group_name = azurerm_network_security_group.main.name
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.network-vnet-cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.network-subnet-cidr]
}

resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

#create network interfaces for the VM's
resource "azurerm_network_interface" "main" {
  count               = var.num_of_vms
  name                = "${var.prefix}-${count.index}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    primary                       = true
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

#create a public IP for the Load Balancer
resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-lb-public-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_lb" "main" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "${var.prefix}-PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_lb_probe" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-http-server-probe"
  port                = 8080
}

resource "azurerm_lb_backend_address_pool" "main" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "${var.prefix}-lb-backend-pool"
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count                   = var.num_of_vms
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

//Create a rule for the LB to route traffic from the 80 port to the backend 8080 port on each VM
resource "azurerm_lb_rule" "main" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "HTTP"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 8080
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
  probe_id                       = azurerm_lb_probe.main.id
  backend_address_pool_id        = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_availability_set" "main" {
  name                        = "${var.prefix}-aset"
  location                    = azurerm_resource_group.main.location
  resource_group_name         = azurerm_resource_group.main.name
  platform_fault_domain_count = 2
}


resource "azurerm_linux_virtual_machine" "main" {
  count                           = var.num_of_vms
  name                            = "${var.prefix}-vm-${count.index}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = var.vm-size
  admin_username                  = var.vm-admin-username
  admin_password                  = var.vm-admin-password
  disable_password_authentication = false
  computer_name                   = "${var.prefix}-vm-${count.index}"

  network_interface_ids = [element(azurerm_network_interface.main.*.id, count.index)]
  availability_set_id   = azurerm_availability_set.main.id

  #use the image we sourced at the beginnng of the script.
  source_image_id = data.azurerm_image.packer-image.id

  os_disk {
    name                 = "${var.prefix}-vm-${count.index}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  tags = {
    environment  = var.environment,
    project-name = "Deploying a HA Web Server in Azure using Terraform"
  }
}

#create a virtual disk for each VM created.
resource "azurerm_managed_disk" "main" {
  count                = var.num_of_vms
  name                 = "data-disk-${count.index}"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 1
}

resource "azurerm_virtual_machine_data_disk_attachment" "main" {
  count              = var.num_of_vms
  managed_disk_id    = azurerm_managed_disk.main.*.id[count.index]
  virtual_machine_id = azurerm_linux_virtual_machine.main.*.id[count.index]
  lun                = 10 * count.index
  caching            = "ReadWrite"
}

######################
## LB - Output      ##
######################

output "lb_url" {
  value       = "http://${azurerm_public_ip.main.ip_address}/"
  description = "The Public URL for the LB."
}

######################
## Network - Output ##
######################

output "network_resource_group_id" {
  value = azurerm_resource_group.main.id
}

output "network_vnet_id" {
  value = azurerm_virtual_network.main.id
}

output "network_subnet_id" {
  value = azurerm_subnet.main.id
}