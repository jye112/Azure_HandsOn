New-AzResourceGroup -Name test-rg -Location KoreaCentral

$rg = "test-rg"
$location = "koreacentral"


#### External Load Balancer ####
$publicip = @{
    Name = 'LB-PublicIP'
    ResourceGroupName = $rg
    Location = $location
    Sku = 'Standard'
    AllocationMethod = 'static'
    Zone = 1,2,3
}
New-AzPublicIpAddress @publicip

$feip = New-AzLoadBalancerFrontendIpConfig -Name 'EXLB-Frontend' -PublicIpAddress $publicip

$bepool = New-AzLoadBalancerBackendAddressPoolConfig -Name 'EXLB-Backend'

$probe = @{
    Name = 'EXLB-HealthProbe'
    Protocol = 'http'
    Port = '80'
    IntervalInSeconds = '360'
    ProbeCount = '5'
    RequestPath = '/'
}

$healthprobe = New-AzLoadBalancerProbeConfig @probe

$lbrule = @{
    Name = 'HTTP-Rule'
    Protocol = 'tcp'
    FrontendPort = '80'
    BackendPort = '80'
    IdleTimeoutInMinutes = '15'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bePool
}

$rule = New-AzLoadBalancerRuleConfig @lbrule -EnableTcpReset -DisableOutboundSNAT

$loadbalancer = @{
    ResourceGroupName = 'test-rg'
    Name = 'External-LB'
    Location = 'koreacentral'
    Sku = 'Standard'
    FrontendIpConfiguration = $feip
    BackendAddressPool = $bepool
    LoadBalancingRule = $rule
    Probe = $healthprobe
}
New-AzLoadBalancer @loadbalancer

#### Network ####
$subnet = @{
    Name = 'Backend-Subnet'
    AddressPrefix = '10.1.0.0/24'
}
$subnetConfig = New-AzVirtualNetworkSubnetConfig @subnet

$bastsubnet = @{
    Name = 'AzureBastionSubnet'
    AddressPrefix = '10.1.1.0/24'
}
$bastsubnetConfig = New-AzVirtualNetworkSubnetConfig @bastsubnet

$vnet = @{
    Name = 'Vnet01'
    ResourceGroupName = 'Test-AzSignalR'
    Location = 'koreacentral'
    AddressPrefix = '10.1.0.0/16'
    Subnet = $subnetConfig, $bastsubnetconfig
}
$vnet = New-AzVirtualNetwork @vnet

$ip = @{
    Name = 'Bastion-IP'
    ResourceGroupName = 'test-rg'
    Location = 'koreacentral'
    Sku = 'Standard'
    AllocationMethod = 'Static'
}
$bastionip = New-AzPublicIpAddress @ip

$bastion = @{
    ResourceGroupName = 'test-rg'
    Name = 'Bastion'
    PublicIpAddress = $bastionip
    VirtualNetwork = $vnet
}
New-AzBastion @bastion -AsJob

$nsgrule = @{
    Name = 'NSG-Rule-HTTP'
    Description = 'Allo HTTP'
    Protocol = '*'
    SourcePortRange = '*'
    DestinationPortRange = '80'
    SourceAddressPrefix = 'Internet'
    DestinationAddressPrefix = '*'
    Access = 'Allow'
    Priority = '2000'
    Direction = 'Inbound'
}
$rule1 = New-AzNetworkSecurityRuleConfig @nsgrule

$nsg = @{
    Name = 'NSG01'
    
}