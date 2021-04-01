# Provider
provider "azurerm" {
    version = "~>2.0"
    features {}
}

# Resource Group 생성
resource "azurerm_resource_group" "rg" {
    name = "ResourceGroup"
    location = "eastus"
}

# VNet01 생성
resource "azurerm_virtual_network" "vnet01" {
    name = "VNet01"
    address_space = ["10.0.0.0/8"]
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

/*
# External Load Balancer NATRule01 생성
resource "azurerm_lb_nat_rule" "externalLB01_NATRule01" {
    resource_group_name = azurerm_resource_group.rg.name
    loadbalancer_id = azurerm_lb.externalLB01.id
    name = "ExternalLB01_NATRule01"
    protocol = "Tcp"
    frontend_port = 5001
    backend_port = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}
*/

/* External Load Balancer NATPool 생성 */
resource "azurerm_lb_nat_pool" "externalLB01_NATPool" {
    resource_group_name            = azurerm_resource_group.rg.name
    name                           = "ExternalLB01_NATPool"
    loadbalancer_id                = azurerm_lb.externalLB01.id
    protocol                       = "Tcp"
    frontend_port_start            = 50000
    frontend_port_end              = 50119
    backend_port                   = 3389
    frontend_ip_configuration_name = "PublicIPAddress"
}

# Virtual Machine Scale Set 생성
resource "azurerm_windows_virtual_machine_scale_set" "vm_scaleset" {
    name                = "VM_ScaleSet"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    sku                 = "Standard_F2"
    instances           = 1
    computer_name_prefix = "vmlab"
    admin_password      = "jeongyeheun7589*"
    admin_username      = "jye112"

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2016-Datacenter-Server-Core"
        version   = "latest"
    }

    os_disk {
        storage_account_type = "Standard_LRS"
        caching              = "ReadWrite"
    }

    network_interface {
        name    = azurerm_network_interface.nic01.name
        primary = true

        ip_configuration {
            name      = "NIC01_IP"
            primary   = true
            subnet_id = azurerm_subnet.subnet01.id
            load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.externalLB01_backendpool.id]
            load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.externalLB01_NATPool.id]
        }
    }
}