# Resource Group 생성
az group create -n MyResourceGroup --location EastUS

# VNet01 생성
az network vnet create -g MyResourceGroup --location eastus -n VNet01 --address-prefixes 10.0.0.0/8

# NSG01 생성
az network nsg create -g MyResourceGroup -n NSG01

# Subnet01 생성
az network vnet subnet create -g MyResourceGroup --vnet-name VNet01 -n Subnet01 --address-prefixes 10.1.0.0/16 --network-security-group NSG01

# NSG01 Rule 생성
az network nsg rule create -g MyResourceGroup --nsg-name NSG01 -n RDP --protocol 'tcp' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow --priority 200

# VM01-NIC 생성
az network nic create -g MyResourceGroup -n NIC01 --vnet-name VNet01 --subnet Subnet01 

# Virtual Machine Scale Set 생성
az vmss create -g MyResourceGroup -n VMScaleSet --image Win2019Datacenter --upgrade-policy-mode automatic --admin-username jye112 --admin-password jeongyeheun7589*

# Public IP 생성
az network public-ip create -g MyResourceGroup -n PublicIP --sku Standard

# ExternalLB01 생성
az network lb create -g MyResourceGroup -n ExternalLB01 --sku Standard --vnet-name VNet01 --public-ip-address PublicIP --frontend-ip-name ExternalLB01_FrontEnd --backend-pool-name ExternalLB01_BackendPool

# ExternalLB01 HealthProbe 생성
az network lb probe create -g MyResourceGroup --lb-name ExternalLB01 -n ExternalLB01_HealthProbe --protocol tcp --port 80

# ExternalLB01 Rule 생성 
az network lb rule create -g MyResourceGroup --lb-name ExternalLB01 -n ExternalLB01_Rule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name ExternalLB01_FrontEnd --backend-pool-name ExternalLB01_BackendPool --probe-name ExternalLB01_HealthProbe --disable-outbound-snat true --idle-timeout 15 --enable-tcp-reset true

# ExternalLB01 Inbound NAT Pool01 생성
az network lb inbound-nat-pool create --backend-port 3389 --frontend-port-range-start 50000 --frontend-port-range-end 50119 --lb-name ExternalLB01 --name InboundNATPool01 --protocol Tcp -g MyResourceGroup --frontend-ip-name ExternalLB01_FrontEnd

# ExternalLB01 Inbound NAT Rule01 생성
# az network lb inbound-nat-rule create -g ResourceGroup --lb-name ExternalLB01 -n InboundNATRule01 --protocol Tcp --frontend-port 5001 --backed-port 3389 --frontend-ip-name ExternalLB01_FrontEnd

# InternalLB01 Inbound NAT Rule01 NIC01 연결
# az network nic ip-config inbound-nat-rule add -g ResourceGroup --nic-name NIC01 -n InboundNATRule01_VM01 --inbound-nat-rule InboundNATRule01

# ExternalLB01 BackendPool에 VM ScaleSet 추가
az network nic ip-config address-pool add --address-pool ExternalLB01_BackendPool --ip-config-name ipconfig1 --nic-name NIC01 -g MyResourceGroup --lb-name ExternalLB01

