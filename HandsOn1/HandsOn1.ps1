# Resource Group 생성
az group create -n test-src-jye --location KoreaCentral

# VNet01 생성
az network vnet create -g test-src-jye --location eastus -n VNet01 --address-prefixes 10.0.0.0/8

# NSG01 생성
az network nsg create -g test-src-jye -n NSG01

# Subnet01 생성
az network vnet subnet create -g test-src-jye --vnet-name VNet01 -n Subnet01 --address-prefixes 10.1.0.0/16 --network-security-group NSG01

# NSG01 Rule 생성
az network nsg rule create -g test-src-jye --nsg-name NSG01 -n RDP --protocol 'tcp' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow --priority 200

# VM01-NIC 생성
az network nic create -g test-src-jye -n NICVM01 --vnet-name VNet01 --subnet Subnet01 

# VM02-NIC 생성
az network nic create -g test-src-jye -n NICVM02 --vnet-name VNet01 --subnet Subnet01 

# VM 01 생성
az vm create -g test-src-jye -n VM01 --nics NICVM01 --image Win2019Datacenter --admin-username jye112 --admin-password jeongyeheun7589*  

# VM 02 생성
az vm create -g test-src-jye -n VM02 --nics NICVM02 --image Win2019Datacenter --admin-username jye112 --admin-password jeongyeheun7589*

# Public IP 생성
az network public-ip create -g test-src-jye --name PublicIPP --sku Standard

# ExternalLB01 생성
az network lb create -g test-src-jye -n ExternalLB01 --sku Standard --vnet-name VNet01 --public-ip-address PublicIP --frontend-ip-name ExternalLB01_FrontEnd --backend-pool-name ExternalLB01_BackendPool

# ExternalLB01 HealthProbe 생성
az network lb probe create -g test-src-jye --lb-name ExternalLB01 -n ExternalLB01_HealthProbe --protocol tcp --port 80

# ExternalLB01 Rule 생성 
az network lb rule create -g test-src-jye --lb-name ExternalLB01 -n ExternalLB01_Rule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name ExternalLB01_FrontEnd --backend-pool-name ExternalLB01_BackendPool --probe-name ExternalLB01_HealthProbe --disable-outbound-snat true --idle-timeout 15 --enable-tcp-reset true

# ExternalLB01 Inbound NAT Rule01 생성
az network lb inbound-nat-rule create -g test-src-jye --lb-name ExternalLB01 -n InboundNATRule01 --protocol Tcp --frontend-port 5001 --backend-port 3389 --frontend-ip-name ExternalLB01_FrontEnd

# InternalLB01 Inbound NAT Rule01 NICVM01 연결
az network nic ip-config inbound-nat-rule add -g test-src-jye --nic-name NICVM01 -n InboundNATRule01_VM01 --inbound-nat-rule InboundNATRule01 --ip-config-name ipconfig1

# ExternalLB01 Inbound NAT Rule02 생성
az network lb inbound-nat-rule create -g test-src-jye --lb-name ExternalLB01 -n InboundNATRule02 --protocol Tcp --frontend-port 5002 --backend-port 3389 --frontend-ip-name ExternalLB01_FrontEnd

# InternalLB01 Inbound NAT Rule02 NICVM02 연결
az network nic ip-config inbound-nat-rule add -g test-src-jye --nic-name NICVM02 -n InboundNATRule02_VM02 --inbound-nat-rule InboundNATRule02 --ip-config-name ipconfig1

# ExternalLB01 BackendPool에 VM01 추가
az network nic ip-config address-pool add --address-pool ExternalLB01_BackendPool --ip-config-name ipconfig1 --nic-name NICVM01 -g test-src-jye --lb-name ExternalLB01

# ExternalLB01 BackendPool에 VM02 추가
az network nic ip-config address-pool add --address-pool ExternalLB01_BackendPool --ip-config-name ipconfig1 --nic-name NICVM02 -g test-src-jye --lb-name ExternalLB01


# Load Balancer Inbound NAT Rule에 VM들이 Target 되지 않음 #