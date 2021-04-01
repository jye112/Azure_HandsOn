
#### Traffic Manager Profile 만들기 ####

$Location1="WestUS"
$ResourceGroup="ResourceGroup"

# Resource Group 생성
New-AzResourceGroup -Name $ResourceGroup -Location $Location1

# Traffic Manager Profile 생성
$Random=(New-Guid).ToString().Substring(0,8)
$mytrafficmanagerprofile="mytrafficmanagerprofile$Random"

New-AzTrafficManagerProfile `
  -Name $mytrafficmanagerprofile `
  -ResourceGroupName $ResourceGroup `
  -TrafficRoutingMethod Priority ` # 라우팅 방법: 우선순위
  -MonitorPath '/' `
  -MonitorProtocol "HTTP" `
  -RelativeDnsName $mytrafficmanagerprofile `
  -Ttl 30 `
  -MonitorPort 80



#### Web App Service 만들기 ####

# Web App Service Plan 생성
$App1Name="AppServiceTM1$Random"
$App2Name="AppServiceTM2$Random"
$Location1="WestUS"
$Location2="EastUS"

New-AzAppservicePlan `
  -Name "$App1Name-Plan" `
  -ResourceGroupName $ResourceGroup `
  -Location $Location1 `
  -Tier Standard

New-AzAppservicePlan `
  -Name "$App2Name-Plan" `
  -ResourceGroupName $ResourceGroup `
  -Location $Location2 `
  -Tier Standard

# Web App Service 생성
$App1ResourceID=(
    New-AzWebApp -Name $App1Name -ResourceGroupName $ResourceGroup -Location $Location1 -AppServicePlan "$App1Name-Plan").ID

$App2ResourceID=(
    New-AzWebApp -Name $App2Name -ResourceGroupName $ResourceGroup -Location $Location2 -AppServicePlan "$App2Name-Plan").ID



#### Traffic Manager Endpoint 추가 ####

New-AzTrafficManagerEndpoint -Name "$App1Name-$Location1" `
  -ResourceGroupName $ResourceGroup `
  -ProfileName "$mytrafficmanagerprofile" `
  -Type AzureEndpoints `
  -TargetResourceId $App1ResourceId `
  -EndpointStatus "Enabled"

New-AzTrafficManagerEndpoint -Name "$App2Name-$Location2" `
  -ResourceGroupName $ResourceGroup `
  -ProfileName "$mytrafficmanagerprofile" `
  -Type AzureEndpoints `
  -TargetResourceId $App2ResourceId `
  -EndpointStatus "Enabled"



#### Traffic Manager Profile Test ####

# DNS 이름 확인 -> mytrafficmanagerprofileaeb8d47e
Get-AzTrafficManagerProfile -Name $mytrafficmanagerprofile `
  -ResourceGroupName $ResourceGroup

# 실행 중인 Traffic Manager 보기
Disable-AzTrafficManagerEndpoint -Name $App1Name-$Location1 `
  -Type AzureEndpoints `
  -ProfileName $mytrafficmanagerprofile `
  -ResourceGroupName $ResourceGroup `
  -Force