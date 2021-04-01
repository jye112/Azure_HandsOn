# Resource Group 생성
az group create -n test-src-jye --location EastUS

# VNet01 생성
az network vnet create -g test-src-jye --location eastus -n VNet01 --address-prefixes 10.0.0.0/8

# VNet02 생성
az network vnet create -g test-src-jye --location eastus -n VNet02 --address-prefixes 192.168.0.0/16 

# NSG01 생성
az network nsg create -g test-src-jye -n NSG01

# NSG02 생성
az network nsg create -g test-src-jye -n NSG02

# Subnet01 생성
az network vnet subnet create -g test-src-jye --vnet-name VNet01 -n Subnet01 --address-prefixes 10.1.0.0/16 --network-security-group NSG01

# Subnet02 생성
az network vnet subnet create -g test-src-jye --vnet-name VNet02 -n Subnet02 --address-prefixes 192.168.1.0/26 --network-security-group NSG02

# NSG01 Rule 생성
az network nsg rule create -g test-src-jye --nsg-name NSG01 -n RDP --protocol 'tcp' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow --priority 200

# NSG02 Rule (RDP) 생성
az network nsg rule create -g test-src-jye --nsg-name NSG02 -n RDP --protocol 'tcp' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range 3389 --access allow --priority 200

# NSG02 Rule (ICMP) 생성
az network nsg rule create -g test-src-jye --nsg-name NSG02 -n ICMP --protocol 'ICMP' --direction inbound --source-address-prefix '*' --source-port-range '*' --destination-address-prefix '*' --destination-port-range '*' --access allow --priority 201

# VM01-NIC 생성
az network nic create -g test-src-jye -n NICVM01 --vnet-name VNet01 --subnet Subnet01 

# VM02-NIC 생성
az network nic create -g test-src-jye -n NICVM02 --vnet-name VNet01 --subnet Subnet01 

# VM03-NIC 생성
az network nic create -g test-src-jye -n NICVM03 --vnet-name VNet02 --subnet Subnet02 

# VM 01 생성
az vm create -g test-src-jye -n VM01 --nics NICVM01 --image Win2019Datacenter --admin-username jye112 --admin-password jeongyeheun7589*  

# VM 02 생성
az vm create -g test-src-jye -n VM02 --nics NICVM02 --image Win2019Datacenter --admin-username jye112 --admin-password jeongyeheun7589*

# VM 03 생성 -> private ip 고정X
az vm create -g test-src-jye -n VM03 --nics NICVM03 --image Win2019Datacenter --admin-username jye112 --admin-password jeongyeheun7589* --private-ip-address 192.168.1.20

# ExternalLB01 생성
az network lb create -g test-src-jye -n ExternalLB01 --sku Standard --vnet-name VNet01 --subnet Subnet01 --frontend-ip-name ExternalLB01_FrontEnd --backend-pool-name ExternalLB01_BackendPool

# ExternalLB01 HealthProbe 생성
az network lb probe create -g test-src-jye --lb-name ExternalLB01 -n ExternalLB01_HealthProbe --protocol tcp --port 80

# ExternalLB01 Rule 생성 
az network lb rule create -g test-src-jye --lb-name ExternalLB01 -n ExternalLB01_Rule --protocol tcp --frontend-port 80 --backend-port 80 --frontend-ip-name ExternalLB01_FrontEnd --backend-pool-name ExternalLB01_BackendPool --probe-name ExternalLB01_HealthProbe --disable-outbound-snat true --idle-timeout 15 --enable-tcp-reset true

# ExternalLB01 BackendPool에 VM01 추가
az network nic ip-config address-pool add --address-pool ExternalLB01_BackendPool --ip-config-name ipconfig1 --nic-name NICVM01 -g test-src-jye --lb-name ExternalLB01

# ExternalLB01 BackendPool에 VM02 추가
az network nic ip-config address-pool add --address-pool ExternalLB01_BackendPool --ip-config-name ipconfig1 --nic-name NICVM02 -g test-src-jye --lb-name ExternalLB01

# Public IP 생성
az network public-ip create -g test-src-jye -n PublicIP --sku Standard

# Peering List 생성
# az network vnet peering list -g test-src-jye --vnet-name VNet1

# Peering 생성 -> 실패
az network vnet peering create -g test-src-jye -n VNet1ToMyVNet2 --vnet-name VNet1 --remote-vnet VNet2 --allow-vnet-access

# Route Table 생성
az network route-table create -g test-src-jye -n RouteTable

# Route Table Route 생성
az network route-table route create -g test-src-jye --route-table-name RouteTable -n Route01 --next-hop-type VirtualAppliance --address-prefix 192.168.0.0/16 --next-hop-ip-address 192.168.1.20