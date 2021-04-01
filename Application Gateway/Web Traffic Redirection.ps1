######################## 기본 구성 ########################

# Resource Group 생성
New-AzResourceGroup -Name ResourceGroup -Location eastus
$ResourceGroup = "ResourceGroup"

# Backend Subnet 설정
$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig `
-Name BackendSubnet `
-AddressPrefix 10.0.1.0/24

# AG Subnet 설정
$agSubnetConfig = New-AzVirtualNetworkSubnetConfig `
-Name AGSubnet `
-AddressPrefix 10.0.2.0/24

# Virtual Network 생성
New-AzVirtualNetwork `
-ResourceGroupName $ResourceGroup `
-Location eastus `
-Name VNet01 `
-AddressPrefix 10.0.0.0/16 `
-Subnet $backendSubnetConfig, $agSubnetConfig

# Public IP 주소 생성
New-AzPublicIpAddress `
-ResourceGroupName $ResourceGroup `
-Location eastus `
-Name PublicIPAddress `
-AllocationMethod Dynamic


######################## Application Gateway 만들기 ########################

#### Frontend 구성 ####

# Virtual Network 가져오기
$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroup `
  -Name VNet01

# Subnet 설정
$subnet = $vnet.Subnets[1]

# Public IP 가져오기
$pip = Get-AzPublicIpAddress `
  -ResourceGroupName $ResourceGroup `
  -Name PublicIPAddress

# Gateway IP 구성
$gipconfig = New-AzApplicationGatewayIPConfiguration `
  -Name AGIPConfig `
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

# Routing Rule 1 설정
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
New-AzApplicationGateway `
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

# Image Backend Pool 추가
Add-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name ImagesBackendPool

# Video Backend Pool 추가
Add-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name VideoBackendPool

# Frontend Port 추가
Add-AzApplicationGatewayFrontendPort `
  -ApplicationGateway $appgw `
  -Name bport `
  -Port 8080

# Frontend Port 추가
Add-AzApplicationGatewayFrontendPort `
  -ApplicationGateway $appgw `
  -Name rport `
  -Port 8081

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw


#### Routing Rule 재구성 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Frontend Port 중 backendPort 가져오기
$backendPort = Get-AzApplicationGatewayFrontendPort `
  -ApplicationGateway $appgw `
  -Name bport

# Frontend Port 중 redirectPort 가져오기
$redirectPort = Get-AzApplicationGatewayFrontendPort `
  -ApplicationGateway $appgw `
  -Name rport

# Frontend IP 가져오기
$fipconfig = Get-AzApplicationGatewayFrontendIPConfig `
  -ApplicationGateway $appgw

# Backend Listener 추가
Add-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name BackendListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $backendPort

# Redirect Listener 추가
Add-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name RedirectListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $redirectPort

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw


#### URL Path Map 규칙 추가하여 재구성 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Http 설정 가져오기
$poolSettings = Get-AzApplicationGatewayBackendHttpSettings `
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

# URL Path Map 규칙 추가
Add-AzApplicationGatewayUrlPathMapConfig `
  -ApplicationGateway $appgw `
  -Name URLPathMap `
  -PathRules $imagePathRule, $videoPathRule `
  -DefaultBackendAddressPool $defaultPool `
  -DefaultBackendHttpSettings $poolSettings

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw


#### Redirection Path Map 추가하여 재구성 ####

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Backend Listener 가져오기
$backendListener = Get-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name BackendListener

# Redirection 설정 추가
$redirectConfig = Add-AzApplicationGatewayRedirectConfiguration `
  -ApplicationGateway $appgw `
  -Name RedirectConfig `
  -RedirectType Found `
  -TargetListener $backendListener `
  -IncludePath $true `
  -IncludeQueryString $true

# HTTP 설정 가져오기
$poolSettings = Get-AzApplicationGatewayBackendHttpSettings `
  -ApplicationGateway $appgw `
  -Name PoolSettings

# Default Backend Pool 가져오기
$defaultPool = Get-AzApplicationGatewayBackendAddressPool `
  -ApplicationGateway $appgw `
  -Name DefaultBackendPool

# Redirection 설정 가져오기
$redirectConfig = Get-AzApplicationGatewayRedirectConfiguration `
  -ApplicationGateway $appgw `
  -Name RedirectConfig

# Redirection Path 규칙 생성
$redirectPathRule = New-AzApplicationGatewayPathRuleConfig `
  -Name RedirectPathRule `
  -Paths "/images/*" `
  -RedirectConfiguration $redirectConfig

# Redirection Path Map 추가
Add-AzApplicationGatewayUrlPathMapConfig `
  -ApplicationGateway $appgw `
  -Name RedirectPathMap `
  -PathRules $redirectPathRule `
  -DefaultBackendAddressPool $defaultPool `
  -DefaultBackendHttpSettings $poolSettings

# Application Gateway 재설정
Set-AzApplicationGateway -ApplicationGateway $appgw

# Application Gateway 가져오기
$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

# Backend Listener 가져오기
$backendlistener = Get-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name BackendListener

# Redirection Listener 가져오기
$redirectlistener = Get-AzApplicationGatewayHttpListener `
  -ApplicationGateway $appgw `
  -Name RedirecteListener

# URL Path Map 가져오기
$urlPathMap = Get-AzApplicationGatewayUrlPathMapConfig `
  -ApplicationGateway $appgw `
  -Name URLPathMap

# Redirect Path Map 가져오기
$redirectPathMap = Get-AzApplicationGatewayUrlPathMapConfig `
  -ApplicationGateway $appgw `
  -Name RedirectPathMap

# Routing Rule 2 추가
Add-AzApplicationGatewayRequestRoutingRule `
  -ApplicationGateway $appgw `
  -Name RoutingRule2 `
  -RuleType PathBasedRouting `
  -HttpListener $backendlistener `
  -UrlPathMap $urlPathMap

# Redirect Path Map Routing Rule 추가 
Add-AzApplicationGatewayRequestRoutingRule `
  -ApplicationGateway $appgw `
  -Name RedirectRoutingRule `
  -RuleType PathBasedRouting `
  -HttpListener $redirectlistener `
  -UrlPathMap $redirectPathMap

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

# ISS 설치
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