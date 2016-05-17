<#

Phase2 of Azure Automation, time to simplify and move forward

>add-azurermaccount
>login-azurermaccount
>get-azuresubscription

Cisco Deploy and Palo Deploy requires: http://go.microsoft.com/fwlink/?LinkId=534873
and
http://stackoverflow.com/questions/34358017/configure-programmatic-deployment-for-azure-bing-maps


#>
<#Notes:
Add DNS Check for viability of rollout i.e.
{
$dnschk = [System.Net.DNS]::GetHostAddresses("name.domain")
}
catch
{
$dnsexist = "false"
}
#>

<#
    variables created to make commands easier to read and shorter,
    resource group names are used in command lines,
    deploy URL is where all the json templates are kept,
    deploy and parameter joins are done to ease path management but be aware
    paths are case sensitive,
    availability group only has one parameter, easier to just feed in as a variables
    build may be changed on some of the simpler deployments to mimic this
    #>

$VDCName = "vdc5"
$coreRG = $VDCName+"core"
$networkRG = $VDCName+"network"
$location = "East US"
$deployURL = "https://raw.githubusercontent.com/tzghardy/project1/master/"
$networkTemplate = $deployURL+"azuredeploy_network.json"
$coreTemplate = $deployURL+"azuredeploy_core.json"
$vnetName = "testvnet"
$dns1 = "10.0.2.21"
$dns2 = "10.0.2.22"

#date
<#create core resource group#>
New-AzureRmResourceGroup -Name $coreRG -Location $location
New-AzureRmResourceGroup -Name $networkRG -Location $location

#date
New-AzureRmResourceGroupDeployment -Name "DeployNetwork" -resourceGroupName $networkRG -templatefile $networkTemplate

New-AzureRmResourceGroupDeployment -Name "DeployCore" -resourceGroupName $coreRG -templatefile $coreTemplate

$vnet = Get-AzureRmVirtualNetwork -resourceGroupName $networkRG -name $vnetName
$vnet.DhcpOptions.DnsServers = $dns1
$vnet.DhcpOptions.DnsServers += $dns2
Set-AzureRmVirtualNetwork -VirtualNetwork $vnetName
