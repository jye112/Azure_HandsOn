# Provider
provider "azurerm" {
    version = "~>2.0"
    features {}
}

# Resource Group 생성
resource "azurerm_resource_group" "rg" {
    name = "test-src-jye"
    location = "koreacentral"
}

# VNet01 생성
resource "azurerm_virtual_network" "vnet01" {
    name = "VNet01"
    address_space = ["10.0.0.0/8"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# VNet02 생성
resource "azurerm_virtual_network" "vnet02" {
    name = "VNet02"
    address_space = ["192.168.0.0/16"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Subnet01 생성
resource "azurerm_subnet" "subnet01" {
    name = "Subnet01"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet01.name
    address_prefixes = ["10.1.0.0/16"]
}

# Subnet02 생성
resource "azurerm_subnet" "subnet02" {
    name = "Subnet02"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet02.name
    address_prefixes = ["192.168.1.0/26"]
}

# NIC01 생성 
resource "azurerm_network_interface" "nic01" {
    name = "NIC01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC01_IP"
        subnet_id = azurerm_subnet.subnet01.id
        private_ip_address_allocation = "Dynamic"
    }
}

# NIC02 생성
resource "azurerm_network_interface" "nic02" {
    name = "NIC02"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC02_IP"
        subnet_id = azurerm_subnet.subnet01.id
        private_ip_address_allocation = "Dynamic"
    }
}

# NIC03 생성
resource "azurerm_network_interface" "nic03" {
    name = "NIC03"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC03_IP"
        subnet_id = azurerm_subnet.subnet02.id
        private_ip_address_allocation = "Dynamic"
    }
}

# AVSet 생성
resource "azurerm_availability_set" "avset" {
    name                = "AVSet"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# VM01 생성
resource "azurerm_windows_virtual_machine" "vm01" {
    name = "VM01"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    availability_set_id = azurerm_availability_set.avset.id
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.nic01.id, 
    ]

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }
}

# VM02 생성
resource "azurerm_windows_virtual_machine" "vm02" {
    name = "VM02"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    availability_set_id = azurerm_availability_set.avset.id
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.nic02.id, 
    ]

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }
}

# VM03 생성
resource "azurerm_windows_virtual_machine" "vm03" {
    name = "VM03"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.nic03.id, 
    ]

    os_disk {
        caching = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter"
        version   = "latest"
    }
}

# NSG01 생성
resource "azurerm_network_security_group" "nsg01" {
    name = "NSG01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# NSG01 Inbound Rule 생성
resource "azurerm_network_security_rule" "nsg01_rule" {
    name = "RDP"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.nsg01.name
}

# NSG01 - Subnet01 연결
resource "azurerm_subnet_network_security_group_association" "nsg01_subnet01" {
    subnet_id = azurerm_subnet.subnet01.id
    network_security_group_id = azurerm_network_security_group.nsg01.id
}

# NSG02 생성
resource "azurerm_network_security_group" "nsg02" {
    name = "NSG02"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# NSG02 Inbound Rule 생성
resource "azurerm_network_security_rule" "nsg02_rule" {
    name = "RDP"
    priority = 100
    direction = "Inbound"
    access = "Allow"
    protocol = "Tcp"
    source_port_range = "*"
    destination_port_range = "*"
    source_address_prefix = "*"
    destination_address_prefix = "*"
    resource_group_name = azurerm_resource_group.rg.name
    network_security_group_name = azurerm_network_security_group.nsg02.name
}

# NSG02 - Subnet02 연결
resource "azurerm_subnet_network_security_group_association" "nsg02_subnet02" {
    subnet_id = azurerm_subnet.subnet02.id
    network_security_group_id = azurerm_network_security_group.nsg02.id
}

# Public IP 생성
resource "azurerm_public_ip" "publicIP" {
    name = "PublicIP_LB"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
}

# External Load Balancer 생성
resource "azurerm_lb" "externalLB01" {
    name = "ExternalLB01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    frontend_ip_configuration {
        name = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.publicIP.id
    }
}

# External Load Balancer Backend Pool 생성
resource "azurerm_lb_backend_address_pool" "externalLB01_backendpool" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.externalLB01.id
    name = "ExternalLB_BackendPool"
}

# External Load Balancer VM01 연결
resource "azurerm_network_interface_backend_address_pool_association" "vm01_lb" {
    network_interface_id = azurerm_network_interface.nic01.id
    ip_configuration_name = "NIC01_IP"
    backend_address_pool_id = azurerm_lb_backend_address_pool.externalLB01_backendpool.id
}

# External Load Balancer VM02 연결
resource "azurerm_network_interface_backend_address_pool_association" "vm02_lb" {
    network_interface_id = azurerm_network_interface.nic02.id
    ip_configuration_name = "NIC02_IP"
    backend_address_pool_id = azurerm_lb_backend_address_pool.externalLB01_backendpool.id
}

# External Load Balancer NATRule01 생성
resource "azurerm_lb_nat_rule" "LB01_NATRule01" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.externalLB01.id
    name = "ExternalLB01_NATRule01"
    protocol = "Tcp"
    frontend_port = 5001
    backend_port = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}

# External Load Balancer NATRule02 생성
resource "azurerm_lb_nat_rule" "LB01_NATRule02" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.externalLB01.id
    name = "ExternalLB01_NATRule02"
    protocol = "Tcp"
    frontend_port = 5002
    backend_port = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}

# External Load Balancer NATRule01 VM01 연결
resource "azurerm_network_interface_nat_rule_association" "NAT01_VM01" {
    network_interface_id = azurerm_network_interface.nic01.id
    ip_configuration_name = "NIC01_IP"
    nat_rule_id = azurerm_lb_nat_rule.LB01_NATRule01.id
}

# External Load Balancer NATRule01 VM02 연결
resource "azurerm_network_interface_nat_rule_association" "NAT02_VM02" {
    network_interface_id = azurerm_network_interface.nic02.id
    ip_configuration_name = "NIC02_IP"
    nat_rule_id = azurerm_lb_nat_rule.LB01_NATRule02.id
}


# Peering (VNet1 -> VNet2)
resource "azurerm_virtual_network_peering" "peering01" {
    name = "Peering1to2"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet01.name
    remote_virtual_network_id = azurerm_virtual_network.vnet02.id
}

resource "azurerm_virtual_network_peering" "peering02" {
    name = "Peering2to1"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet02.name
    remote_virtual_network_id = azurerm_virtual_network.vnet01.id
}


# Route Table 생성
resource "azurerm_route_table" "rt" {
    name = "RouteTable01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    disable_bgp_route_propagation = false

    route {
        name = "route01"
        address_prefix = "192.168.0.0/16"
        next_hop_type = "VirtualAppliance"
        next_hop_in_ip_address = azurerm_network_interface.nic03.private_ip_address
    }
}