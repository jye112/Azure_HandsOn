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

# Application Gateway에 Public IP 할당
$fipconfig = New-AzApplicationGatewayFrontendIPConfig `
  -Name AGFrontendIPConfig `
  -PublicIPAddress $pip

# Application Gateway Frontend Port 설정
$frontendport = New-AzApplicationGatewayFrontendPort `
  -Name FrontendPort `
  -Port 80

# Application Gateway Backendpool - contosopool
$contosoPool = New-AzApplicationGatewayBackendAddressPool `
  -Name contosoPool

# Application Gateway Backendpool - fabrikampool
$fabrikamPool = New-AzApplicationGatewayBackendAddressPool `
  -name fabrikamPool

# Backendpool Http 설정 - contoso와 fabrikam 모두 공유
$poolSettings = New-AzApplicationGatewayBackendHttpSettings `
  -Name myPoolSettings `
  -Port 80 `
  -Protocol Http `
  -CookieBasedAffinity Enabled `
  -RequestTimeout 120

# Application Gateway Http Listener - contosolistener
$contosolistener = New-AzApplicationGatewayHttpListener `
  -Name contosoListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendport `
  -HostName "www.contoso.com"

# Application Gateway Http Listener - fabrikamlistener
$fabrikamlistener = New-AzApplicationGatewayHttpListener `
  -Name fabrikamListener `
  -Protocol Http `
  -FrontendIPConfiguration $fipconfig `
  -FrontendPort $frontendport `
  -Hostname "www.fabrikam.com"

# Application Gateway Routing Rule - contosoRule
$contosoRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name contosoRule `
  -RuleType Basic `
  -HttpListener $contosoListener `
  -BackendAddressPool $contosoPool `
  -BackendHttpSettings $poolSettings

# Application Gateway Routing Rule - fabrikamRule
$fabrikamRule = New-AzApplicationGatewayRequestRoutingRule `
  -Name fabrikamRule `
  -RuleType Basic `
  -HttpListener $fabrikamListener `
  -BackendAddressPool $fabrikamPool `
  -BackendHttpSettings $poolSettings

# Application Gateway SKU 설정
$sku = New-AzApplicationGatewaySku `
  -Name Standard_Medium `
  -Tier Standard `
  -Capacity 2

# Application Gateway 생성
$appgw = New-AzApplicationGateway `
  -Name AppGateway `
  -ResourceGroupName $ResourceGroup `
  -Location eastus `
  -BackendAddressPools $contosoPool, $fabrikamPool `
  -BackendHttpSettingsCollection $poolSettings `
  -FrontendIpConfigurations $fipconfig `
  -GatewayIpConfigurations $gipconfig `
  -FrontendPorts $frontendport `
  -HttpListeners $contosoListener, $fabrikamListener `
  -RequestRoutingRules $contosoRule, $fabrikamRule `
  -Sku $sku


######################## Application Gateway Test ########################

$vnet = Get-AzVirtualNetwork `
  -ResourceGroupName $ResourceGroup `
  -Name VNet01

$appgw = Get-AzApplicationGateway `
  -ResourceGroupName $ResourceGroup `
  -Name AppGateway

$contosoPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name contosoPool `
  -ApplicationGateway $appgw

$fabrikamPool = Get-AzApplicationGatewayBackendAddressPool `
  -Name fabrikamPool `
  -ApplicationGateway $appgw

for ($i=1; $i -le 2; $i++)
{
  if ($i -eq 1) 
  {
    $poolId = $contosoPool.Id
  }
  if ($i -eq 2)
  {
    $poolId = $fabrikamPool.Id
  }

  $ipConfig = New-AzVmssIpConfig `
    -Name VmssIPConfig$i `
    -SubnetId $vnet.Subnets[0].Id `
    -ApplicationGatewayBackendAddressPoolsId $poolId

  $vmssConfig = New-AzVmssConfig `
    -Location centralus `
    -SkuCapacity 2 `
    -SkuName Standard_DS2 `
    -UpgradePolicyMode Automatic

  Set-AzVmssStorageProfile $vmssConfig `
    -ImageReferencePublisher MicrosoftWindowsServer `
    -ImageReferenceOffer WindowsServer `
    -ImageReferenceSku 2016-Datacenter `
    -ImageReferenceVersion latest `
    -OsDiskCreateOption FromImage

  Set-AzVmssOsProfile $vmssConfig `
    -AdminUsername jye112 `
    -AdminPassword "jeongyeheun7589*" `
    -ComputerNamePrefix myvmss$i

  Add-AzVmssNetworkInterfaceConfiguration `
    -VirtualMachineScaleSet $vmssConfig `
    -Name myVmssNetConfig$i `
    -Primary $true `
    -IPConfiguration $ipConfig

  New-AzVmss `
    -ResourceGroupName $ResourceGroup `
    -Name myvmss$i `
    -VirtualMachineScaleSet $vmssConfig
}

$publicSettings = @{ "fileUris" = (,"https://raw.githubusercontent.com/Azure/azure-docs-powershell-samples/master/application-gateway/iis/appgatewayurl.ps1"); 
  "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File appgatewayurl.ps1" }

for ($i=1; $i -le 2; $i++)
{
  $vmss = Get-AzVmss `
    -ResourceGroupName $ResourceGroup `
    -VMScaleSetName myvmss$i

  Add-AzVmssExtension -VirtualMachineScaleSet $vmss `
    -Name "customScript" `
    -Publisher "Microsoft.Compute" `
    -Type "CustomScriptExtension" `
    -TypeHandlerVersion 1.8 `
    -Setting $publicSettings

  Update-AzVmss `
    -ResourceGroupName $ResourceGroup `
    -Name myvmss$i `
    -VirtualMachineScaleSet $vmss
}


######################## Application Gateway Test ########################

# contosopool에 contosoVM 추가
$subnet=$vnet.Subnets[1]

New-AzVm `
  -ResourceGroupName $ResourceGroup `
  -Name "contosoVM" `
  -Location "East US" `
  -VirtualNetworkName "VNet01" `
  -SubnetName "BackendSubnet" `
  -PublicIPAddress "PublicIP" `
  -OpenPorts 80,3389


# fabrikampool에 fabrikamApp 추가
New-AzAppservicePlan `
  -Name "fabrikamAppPlan" `
  -ResourceGroupName $ResourceGroup `
  -Location "eastus" `
  -Tier Standard

New-AzWebApp `
  -Name "fabrikamApp" 
  -ResourceGroupName $ResourceGroup 
  -Location "eastus" 
  -AppServicePlan "fabrikamAppPlan"


# Test를 위해 VM에 IIS 설치
Set-AzVMExtension `
  -ResourceGroupName $ResourceGroup `
  -ExtensionName IIS `
  -VMName contosoVM `
  -Publisher Microsoft.Compute `
  -ExtensionType CustomScriptExtension `
  -TypeHandlerVersion 1.4 `
  -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
  -Location eastus