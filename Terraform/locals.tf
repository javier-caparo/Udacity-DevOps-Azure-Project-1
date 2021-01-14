locals { 
nsgrules = {
   
    http = {
      name                       = "http"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    VNetInBound-Allow = {
      name                       = "VNetInBound-Allow"
      priority                   = 4000
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }

    LoadBalancerInBound-Allow = {
      name                       = "LoadBalancerInBound-Allow"
      priority                   = 4001
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "AzureLoadBalancer"
      destination_address_prefix = "*"
    }

    Inbound-DenyAll = {
      name                       = "Inbound-DenyAll"
      priority                   = 4050
      direction                  = "Inbound"
      access                     = "Deny"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range    = "*"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }

    VnetOutBound-Allow = {
      name                       = "VnetOutBound-Allow"
      priority                   = 4000
      direction                  = "Outbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_range     = "*"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }

  }
}