# Provider
provider "azurerm" {
    version = "~>2.0"
    features {}
}

# Resource Group 생성
resource "azurerm_resource_group" "rg" {
    name = "MyResourceGroup"
    location = "eastus"
}

# VNet01 생성
resource "azurerm_virtual_network" "VNet01" {
    name = "VNet01"
    address_space = ["10.0.0.0/8"]
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# Subnet01 생성
resource "azurerm_subnet" "Subnet01" {
    name = "Subnet01"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.VNet01.name
    address_prefixes = ["10.1.0.0/16"]
}

# Subnet02 생성
resource "azurerm_subnet" "Subnet02" {
    name = "Subnet02"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.VNet01.name
    address_prefixes = ["10.2.0.0/16"]
}

# NIC01 생성 
resource "azurerm_network_interface" "NIC01" {
    name = "NIC01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC01_IP"
        subnet_id = azurerm_subnet.Subnet01.id
        private_ip_address_allocation = "Dynamic"
    }
}

# NIC02 생성
resource "azurerm_network_interface" "NIC02" {
    name = "NIC02"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC02_IP"
        subnet_id = azurerm_subnet.Subnet01.id
        private_ip_address_allocation = "Dynamic"
    }
}

# NIC03 생성
resource "azurerm_network_interface" "NIC03" {
    name = "NIC03"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC03_IP"
        subnet_id = azurerm_subnet.Subnet02.id
        private_ip_address_allocation = "Dynamic"
    }
}

# NIC04 생성
resource "azurerm_network_interface" "NIC04" {
    name = "NIC04"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    
    ip_configuration {
        name = "NIC04_IP"
        subnet_id = azurerm_subnet.Subnet02.id
        private_ip_address_allocation = "Dynamic"
    }
}

# AVSet01 생성
resource "azurerm_availability_set" "AVSet01" {
    name                = "AVSet01"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# AVSet02 생성
resource "azurerm_availability_set" "AVSet02" {
    name                = "AVSet02"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# VM01 생성
resource "azurerm_windows_virtual_machine" "VM01" {
    name = "VM01"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    availability_set_id = azurerm_availability_set.AVSet01.id
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.NIC01.id, 
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
resource "azurerm_windows_virtual_machine" "VM02" {
    name = "VM02"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    availability_set_id = azurerm_availability_set.AVSet01.id
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.NIC02.id, 
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
resource "azurerm_windows_virtual_machine" "VM03" {
    name = "VM03"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    availability_set_id = azurerm_availability_set.AVSet02.id
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.NIC03.id, 
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

# VM04 생성
resource "azurerm_windows_virtual_machine" "VM04" {
    name = "VM04"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    availability_set_id = azurerm_availability_set.AVSet02.id
    size = "Standard_F2"
    admin_username = "jye112"
    admin_password = "jeongyeheun7589*"
    network_interface_ids = [
        azurerm_network_interface.NIC04.id, 
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
resource "azurerm_network_security_group" "NSG01" {
    name = "NSG01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# NSG01 Inbound Rule 생성
resource "azurerm_network_security_rule" "NSG01_Rule" {
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
    network_security_group_name = azurerm_network_security_group.NSG01.name
}

# NSG01 - Subnet01 연결
resource "azurerm_subnet_network_security_group_association" "NSG01_Subnet01" {
    subnet_id = azurerm_subnet.Subnet01.id
    network_security_group_id = azurerm_network_security_group.NSG01.id
}

# NSG02 생성
resource "azurerm_network_security_group" "NSG02" {
    name = "NSG02"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

# NSG02 Inbound Rule 생성
resource "azurerm_network_security_rule" "NSG02_Rule" {
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
    network_security_group_name = azurerm_network_security_group.NSG02.name
}

# NSG02 - Subnet02 연결
resource "azurerm_subnet_network_security_group_association" "NSG02_Subnet02" {
    subnet_id = azurerm_subnet.Subnet02.id
    network_security_group_id = azurerm_network_security_group.NSG02.id
}

# External Load Balancer Public IP 생성
resource "azurerm_public_ip" "PublicIP_LB" {
    name = "PublicIP_LB"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
}

# External Load Balancer 생성
resource "azurerm_lb" "ExternalLB01" {
    name = "ExternalLB01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    frontend_ip_configuration {
        name = "PublicIPAddress"
        public_ip_address_id = azurerm_public_ip.PublicIP_LB.id // External Load Balancer Public IP를 사용
        /* public ip address가 있으면 subnet을 쓰지 않아도 됨 */
    }
}

# External Load Balancer Backend Pool 생성
resource "azurerm_lb_backend_address_pool" "ExternalLB01_Backendpool" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.ExternalLB01.id
    name = "ExternalLB01_BackendPool"
}

# External Load Balancer VM01 연결
resource "azurerm_network_interface_backend_address_pool_association" "VM01_lb" {
    network_interface_id = azurerm_network_interface.NIC01.id
    ip_configuration_name = "NIC01_IP"
    backend_address_pool_id = azurerm_lb_backend_address_pool.ExternalLB01_Backendpool.id
}

# External Load Balancer VM02 연결
resource "azurerm_network_interface_backend_address_pool_association" "VM02_lb" {
    network_interface_id = azurerm_network_interface.NIC02.id
    ip_configuration_name = "NIC02_IP"
    backend_address_pool_id = azurerm_lb_backend_address_pool.ExternalLB01_Backendpool.id
}

# External Load Balancer NATRule01 생성
resource "azurerm_lb_nat_rule" "ExternalLB01_NATRule01" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.ExternalLB01.id
    name = "ExternalLB01_NATRule01"
    protocol = "Tcp"
    frontend_port = 5001
    backend_port = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}

# External Load Balancer NATRule02 생성
resource "azurerm_lb_nat_rule" "ExternalLB01_NATRule02" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.ExternalLB01.id
    name = "ExternalLB01_NATRule02"
    protocol = "Tcp"
    frontend_port = 5002
    backend_port = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}

# External Load Balancer NATRule01 VM01 연결
resource "azurerm_network_interface_nat_rule_association" "NAT01_VM01" {
    network_interface_id = azurerm_network_interface.NIC01.id
    ip_configuration_name = "NIC01_IP"
    nat_rule_id = azurerm_lb_nat_rule.ExternalLB01_NATRule01.id
}

# External Load Balancer NATRule01 VM02 연결
resource "azurerm_network_interface_nat_rule_association" "NAT02_VM02" {
    network_interface_id = azurerm_network_interface.NIC02.id
    ip_configuration_name = "NIC02_IP"
    nat_rule_id = azurerm_lb_nat_rule.ExternalLB01_NATRule02.id
}

# Internal Load Balancer 생성
resource "azurerm_lb" "InternalLB01" {
    name = "InternalLB01"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    frontend_ip_configuration {
        name = "PrivateIPAddress"
        subnet_id = azurerm_subnet.Subnet02.id // private ip address을 자동으로 할당해야 하므로 Subnet 명시가 필요 -> Subnet의 IP 대역 범위에 맞춰 할당되므로
        private_ip_address_allocation = "Dynamic"
    }
}

# Internal Load Balancer Backend Pool 생성
resource "azurerm_lb_backend_address_pool" "InternalLB01_Backendpool" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.InternalLB01.id
    name = "InternalLB_BackendPool"
}

# Internal Load Balancer VM03 연결
resource "azurerm_network_interface_backend_address_pool_association" "VM03_lb" {
    network_interface_id = azurerm_network_interface.NIC03.id
    ip_configuration_name = "NIC03_IP"
    backend_address_pool_id = azurerm_lb_backend_address_pool.InternalLB01_Backendpool.id
}

# Internal Load Balancer VM04 연결
resource "azurerm_network_interface_backend_address_pool_association" "VM04_lb" {
    network_interface_id = azurerm_network_interface.NIC04.id
    ip_configuration_name = "NIC04_IP"
    backend_address_pool_id = azurerm_lb_backend_address_pool.InternalLB01_Backendpool.id
}

# Internal Load Balancer NATRule01 생성
resource "azurerm_lb_nat_rule" "InternalLB01_NATRule01" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.InternalLB01.id
    name = "InternalLB01_NATRule01"
    protocol = "Tcp"
    frontend_port = 5003
    backend_port = 3389
    frontend_ip_configuration_name = "PrivateIPAddress"
}

# Internal Load Balancer NATRule02 생성
resource "azurerm_lb_nat_rule" "InternalLB01_NATRule02" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.InternalLB01.id
    name = "InternalLB01_NATRule02"
    protocol = "Tcp"
    frontend_port = 5004
    backend_port = 3389
    frontend_ip_configuration_name = "PrivateIPAddress"
}

# Internal Load Balancer NATRule01 VM03 연결
resource "azurerm_network_interface_nat_rule_association" "NAT01_VM03" {
    network_interface_id = azurerm_network_interface.NIC03.id
    ip_configuration_name = "NIC03_IP"
    nat_rule_id = azurerm_lb_nat_rule.InternalLB01_NATRule01.id
}

# Internal Load Balancer NATRule02 VM04 연결
resource "azurerm_network_interface_nat_rule_association" "NAT02_VM04" {
    network_interface_id = azurerm_network_interface.NIC04.id
    ip_configuration_name = "NIC04_IP"
    nat_rule_id = azurerm_lb_nat_rule.InternalLB01_NATRule02.id
}

# Bastion Host Subnet 생성
 resource "azurerm_subnet" "AzureBastionSubnet" {
     name = "AzureBastionSubnet"
     resource_group_name = azurerm_resource_group.rg.name
     virtual_network_name = azurerm_virtual_network.VNet01.name
     address_prefixes = ["10.100.0.0/24"]
 }

# Bastion Host Public IP 생성
resource "azurerm_public_ip" "PublicIP_BastionHost" {
    name = "PublicIP_BastionHost"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
    sku = "Standard"
}

# Bastion Host 생성
resource "azurerm_bastion_host" "Bastion_Host" {
    name = "Bastion_Host"
    location = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name = "BastionHost_PublicIP"
        subnet_id = azurerm_subnet.AzureBastionSubnet.id
        public_ip_address_id = azurerm_public_ip.PublicIP_BastionHost.id
    }
}

# Storage Account 생성
resource "azurerm_storage_account" "Storage_Account" {
    name = "jyestorageaccount"
    resource_group_name = azurerm_resource_group.rg.name
    location = azurerm_resource_group.rg.location
    account_kind = "FileStorage"
    account_tier = "Premium"
    account_replication_type = "LRS"
}


# Storage Share 생성
resource "azurerm_storage_share" "Storage_Share" {
    name = "myshare"
    storage_account_name = azurerm_storage_account.Storage_Account.name
    quota = 50
}


# Storage File Share
resource "azurerm_storage_share" "example" {
  name             = "file.txt"
  storage_share_id = azurerm_storage_share.Storage_Share.id
  source           = "example.txt"
}
*/