######################## 기본 구성 ########################

# Resource Group 생성
New-AzResourceGroup -Name ResourceGroup -Location eastus

# Backend Subnet 
$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name BackendSubnet `
  -AddressPrefix 10.0.1.0/24

# Application Gateway Subnet 
$agSubnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name AGSubnet `
  -AddressPrefix 10.0.2.0/24

# Virtual Network 생성
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroup `
  -Location eastus `
  -Name VNet01 `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $backendSubnetConfig, $agSubnetConfig

# Public IP 생성
$pip = New-AzPublicIpAddress `
  -ResourceGroupName $ResourceGroup `
  -Location eastus `
  -Name AGPublicIPAddress `
  -AllocationMethod Dynamic

######################## Application Gateway 만들기 ########################

#### Frontend 구성 ####

# Virtual Network 가져오기
$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroup `
  -Name VNet01

# Subnet 설정
$subnet=$vnet.Subnets[1]

# Gateway IP 구성
$gipconfig = New-AzApplicationGatewayIPConfiguration `
  -Name AGIPconfig `
  -Subnet $subnet


#### Backend 구성 ####

# Default Pool 생성
$defaultPool = New-AzApplicationGatewayBackendAddressPool `
  -Name DefaultBackendPool


#### Routing Rule 구성 ####

# Frontend에 Public IP 설정
$fipconfig = New-AzApplicationGatewayFrontendIPConfig `
  -Name AGFrontendIPConfig `
  -PublicIPAddress $pip

# Frontend Port 설정
$frontendport = New-AzApplicationGatewayFrontendPort `
  -Name FrontendPort `
  -Port 80

# Default Listener 설정
$defaultlistener = New-AzApplicationGatewayHttpListener `
  -Name DefaultListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendport

# Http 설정
$poolSettings = New-AzApplicationGatewayBackendHttpSetting `
  -Name PoolSettings `
  -Port 80 `
  -Protocol Http `
  -CookieBasedAffinity Enabled `
  -RequestTimeout 120

# Routing Rule 01 설정
$frontendRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name RoutingRule1 `
  -RuleType Basic `
  -HttpListener $defaultlistener `
  -BackendAddressPool $defaultPool `
  -BackendHttpSettings $poolSettings

# Application Gateway 구성요소 설정
$sku = New-AzApplicationGatewaySku `
  -Name Standard_Medium `
  -Tier Standard `
  -Capacity 2

# Application Gateway 생성
$appgw = New-AzApplicationGateway `
  -Name AppGateway `
  -ResourceGroupName $ResourceGroup `
  -Location eastus `
  -BackendAddressPools $defaultPool `
  -BackendHttpSettingsCollection $poolSettings `
  -FrontendIpConfigurations $fipconfig `
  -GatewayIpConfigurations $gipconfig `
  -FrontendPorts $frontendport `
  -HttpListeners $defaultlistener `
  -RequestRoutingRules $frontendRule `
  -Sku $sku



#### Image & Video Backend Pool 추가 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Images Backend Pool 추가
Add-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name ImagesBackendPool

# Videos Backend Pool 추가
Add-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name VideoBackendPool

# Frontend Port 추가
Add-AzApplicationGatewayFrontendPort `
  -ApplicationGateway $appgw `
  -Name bport `
  -Port 8080

# Application Gateway 재설정
Set-AzApplicationGateway -Applic ationGateway $appgw


#### Routing Rule 재구성 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Frontend Port 가져오기
$backendPort = Get-AzApplicationGatewayFrontendPort `
  -ApplicationGateway $appgw `
  -Name bport

# Frontend IP 가져오기
$fipconfig = Get-AzApplicationGatewayFrontendIPConfig `
  -ApplicationGateway $appgw

# 새로운 Backend Listener 추가
Add-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name BackendListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $backendPort

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw


#### URL Path Map 추가 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Http 설정 가져오기
$poolSettings = Get-AzApplicationGatewayBackendHttpSetting `
  -ApplicationGateway $appgw `
  -Name PoolSettings

# Image Backend Pool 가져오기
$imagePool = Get-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name ImagesBackendPool

# Video Backend Pool 가져오기
$videoPool = Get-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name VideoBackendPool

# Default Backend Pool 가져오기
$defaultPool = Get-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name DefaultBackendPool

# Image Path Rule 설정
$imagePathRule = New-AzApplicationGatewayPathRuleConfig `
  -Name ImagePathRule `
  -Paths "/images/*" `
  -BackendAddressPool $imagePool `
  -BackendHttpSettings $poolSettings

# Video Path Rule 설정
$videoPathRule = New-AzApplicationGatewayPathRuleConfig `
  -Name VideoPathRule `
    -Paths "/video/*" `
    -BackendAddressPool $videoPool `
    -BackendHttpSettings $poolSettings

# Application Gateway URL 경로 추가
Add-AzApplicationGatewayUrlPathMapConfig `
  -ApplicationGateway $appgw `
  -Name URLPathMap `
  -PathRules $imagePathRule, $videoPathRule `
  -DefaultBackendAddressPool $defaultPool `
  -DefaultBackendHttpSettings $poolSettings

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw


#### URL Path Map 규칙 적용된 Routing Rule 재구성 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Backend Listener 가져오기
$backendlistener = Get-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name BackendListener

# URL Path Map 가져오기
$urlPathMap = Get-AzApplicationGatewayUrlPathMapConfig `
  -ApplicationGateway $appgw `
  -Name URLPathMap

# 경로 기반 (URL Path Map 적용된) Routing Rule 추가
Add-AzApplicationGatewayRequestRoutingRule `
  -ApplicationGateway $appgw `
  -Name RoutingRule2 `
  -RuleType PathBasedRouting `
  -HttpListener $backendlistener `
  -UrlPathMap $urlPathMap

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw


#### Virtual Machine 생성 후 테스트 ####

# Virtual Network 가져오기
$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroup `
  -Name VNet01

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Backend Pool 가져오기
$backendPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name DefaultBackendPool `
  -ApplicationGateway $appgw

# Image Backend Pool 가져오기
$imagesPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name ImagesBackendPool `
  -ApplicationGateway $appgw

# Video Backend Pool 가져오기
$videoPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name VideoBackendPool `
  -ApplicationGateway $appgw

# VM 2개 생성

# IIS 설치

$publicSettings = @{ "fileUris" = (,"https://raw.githubusercontent.com/Azure/azure-docs-powershell-samples/master/application-gateway/iis/appgatewayurl.ps1"); 
  "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File appgatewayurl.ps1" }

Set-AzVMExtension `
  -ResourceGroupName $ResourceGroup `
  -ExtensionName IIS `
  -VMName VM01 `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.4 `
  -Settings $publicSettings `
  -Location eastus

Set-AzVMExtension `
  -ResourceGroupName $ResourceGroup `
  -ExtensionName IIS `
  -VMName VM02 `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.4 `
  -Settings $publicSettings `
  -Location eastus

# Virtual Machine Scale Sets 생성
#for ($i=1; $i -le 3; $i++)
#{
#  if ($i -eq 1)
#  {
#     $poolId = $backendPool.Id
#  }
#  if ($i -eq 2) 
#  {
#    $poolId = $imagesPool.Id
#  }
#  if ($i -eq 3)
#  {
#    $poolId = $videoPool.Id
#  }
#
#  $ipConfig = New-AzVmssIpConfig `
#    -Name myVmssIPConfig$i `
#    -SubnetId $vnet.Subnets[1].Id `
#    -ApplicationGatewayBackendAddressPoolsId $poolId
#
#  $vmssConfig = New-AzVmssConfig `
#    -Location koreacentral `
#    -SkuCapacity 2 `
#    -SkuName Standard_D2s_v3 `
#    -UpgradePolicyMode Automatic
#
#  Set-AzVmssStorageProfile $vmssConfig `
#    -ImageReferencePublisher MicrosoftWindowsServer `
#    -ImageReferenceOffer WindowsServer `
#    -ImageReferenceSku 2016-Datacenter `
#    -ImageReferenceVersion latest `
#    -OsDiskCreateOption FromImage
#
#  Set-AzVmssOsProfile $vmssConfig `
#    -AdminUsername jye112 `
#    -AdminPassword "jeongyeheun7589*" `
#    -ComputerNamePrefix myvmss$i
#
#  Add-AzVmssNetworkInterfaceConfiguration `
#    -VirtualMachineScaleSet $vmssConfig `
#    -Name myVmssNetConfig$i `
#    -Primary $true `
#    -IPConfiguration $ipConfig
#
#  New-AzVmss `
#    -ResourceGroupName $ResourceGroup `
#    -Name myvmss$i `
#    -VirtualMachineScaleSet $vmssConfig
#}
#


