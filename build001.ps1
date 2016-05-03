<#

Phase2 of Azure Automation, time to simplify and move forward

>add-azurermaccount
>login-azurermaccount
>get-azuresubscription

Cisco Deploy requires: http://go.microsoft.com/fwlink/?LinkId=534873
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

$VDCName = "VDC2"
$coreRG = $VDCName+"core"
$networkRG = $VDCName+"network"
$location = "East US"
$deployURL = "https://raw.githubusercontent.com/tzghardy/project1/master/"

#build paths to templates and parameters
$deploystorage = $deployURL+"StorageAccount/azuredeploy.json"
$parametersstoragecore = $deployURL+"StorageAccount/azuredeploy_core.parameters.json"
$parametersstoragenetwork = $deployURL+"StorageAccount/azuredeploy_network.parameters.json"
$deploynsg = $deployURL+"NetSecGroup/azuredeploy.json"
$parametersnsg = $deployURL+"NetSecGroup/azuredeploy.parameters.json"
$deployvnet = $deployURL+"VNET/azuredeploy.json"
$parametersvnet = $deployURL+"VNET/azuredeploy.parameters.json"
$deployvnetwdns = $deployURL+"VNET/azuredeploy_wdns.json"
$parametersvnetdns1 = $deployURL+"VNET/azuredeploy_wdns1.parameters.json"
$parametersvnetdns2 = $deployURL+"VNET/azuredeploy_wdns2.parameters.json"
$deployavset = $deployURL+"AvailabilitySet/azuredeploy.json"
$deploydc = $deployURL+"AD_NewDomain/azuredeploy_dc.json"
$parameterspdc = $deployURL+"AD_NewDomain/azuredeploy_pdc.parameters.json"
$parametersbdc = $deployURL+"AD_NewDomain/azuredeploy_bdc.parameters.json"
$deploycsr = $deployURL+"cisco-csr-1000v/azuredeploy.json"
$parameterscsr = $deployURL+"cisco-csr-1000v/azuredeploy.parameters.json"

#parameterobjects
<# storagetype allowed values
"Standard_LRS","Standard_LRSZRS","Standard_LRSGRS","Standard_RAGRS","Premium_LRS"
#>
$storagetype_core = "Standard_LRS"
$storagetype_network = "Standard_LRS"
$subnetNameFrontEndFixed = "FEFixed"
$subnetNameFrontEndDynamic = "FEDynamic"
$subnetNameBackEndFixed = "BEFixed"
$subnetNameBackEndDynamic = "BEDynamic"
$subnetNameSECFixed = "SECFixed"
$parametersavset = @{"AvailabilitySetName"="adAvailabilitySet"}
$parametersNSG = @{"VDCName"=$VDCName;"subnetFEfixedName"=$subnetNameFrontEndFixed;"subnetFEdynamicName"=$subnetNameFrontEndDynamic;"subnetBEfixedName"=$subnetNameBackEndFixed;"subnetBEdynamicName"=$subnetNameBackEndDynamic;"subnetSECfixedName"=$subnetNameSECFixed}


#date
<#create core resource group#>
New-AzureRmResourceGroup -Name $coreRG -Location $location

#date
<#create Storage Account in resource group
parameters file only had storage type so I've removed it as an object
storage account name is being created by the script
#>
$storageAccountNameCore=$coreRG+$storageType_core.Substring(0,1)+$storageType_core.Split('_')[1]
$storageAccountNameCore=$storageAccountNameCore.toLower()
New-AzureRmResourceGroupDeployment -Name "Core_Storage_Account" -ResourceGroupName $coreRG -TemplateURI $deploystorage -storageType $storageType_core -storageAccountName $storageAccountNameCore

#date
<#create Network Resrouce Group#>
New-AzureRmResourceGroup -Name $networkRG -Location $location

#date
<#
    create StorageAccount in resource group output is storageNameOutput = storageaccountname...
    this could be used later to push deployments together#>
$storageAccountNameNetwork=$networkRG+$storageType_network.Substring(0,1)+$storageType_network.Split('_')[1]
$storageAccountNameNetwork=$storageAccountNameNetwork.toLower()
New-AzureRmResourceGroupDeployment -Name "Network_Storage_Account"-ResourceGroupName $networkRG -TemplateURI $deploystorage -storageType $storageType_network -storageAccountName $storageAccountNameNetwork

#date
<#create NSG for VDC1, there are no actual rules in this template besides letting it build defualts#>
New-AzureRmResourceGroupDeployment -Name "NetSecGroup_Deploy"-ResourceGroupName $networkRG -TemplateURI $deploynsg -TemplateParameterObject $parametersNSG

<#create UDR for VDC1, this needs to be moved to post virtual appliance install when it gets built, new vnet deploy script will be required though it is already mostly built#>
<#not_working (no Virt Appliance) New-AzureRmResourceGroupDeployment -ResourceGroupName "rgVDC1network" -TemplateURI "./UserDefRoute/azuredeploy.json" -TemplateParameterURI "./UserDefRoute/azuredeploy.parameters.json"
#>

#date
<#create virtualNetwork with 5 subnets (FE Fixed, FE Dynamic, BE Fixed, BE Dyanmic, Security Mgmt)#>
#New-AzureRmResourceGroupDeployment -Name "vNet_Deploy" -ResourceGroupName $networkRG -TemplateURI $deployvnet -TemplateParameterURI $parametersvnet

#date
<#create availability set form AD#>
#New-AzureRmResourceGroupDeployment -Name "AD_Availability_Set" -ResourceGroupName $coreRG -TemplateURI $deployavset -TemplateParameterObject $parametersavset

#date
<#create AD PDC, this takes 20-45 minutes since it builds a domain#>
#New-AzureRmResourceGroupDeployment -Name "PDC_Deploy" -ResourceGroupName $coreRG -TemplateURI $deploydc -TemplateParameterURI $parameterspdc

#date
<#fix vnet DNS configuration with 1st server#>
#New-AzureRmResourceGroupDeployment -Name "Add_PDC_DNS"-ResourceGroupName $networkRG -TemplateURI $deployvnetwdns -TemplateParameterURI $parametersvnetdns1

#date
<#create AD BDC, this takes 20-45 minutes since it promotes and replicates the domain#>
#New-AzureRmResourceGroupDeployment -Name "BDC_Deploy"-ResourceGroupName $coreRG -TemplateURI $deploydc -TemplateParameterURI $parametersbdc

#date
<#fix vnet DNS configuration with 2nd server#>
#New-AzureRmResourceGroupDeployment -Name "Add_BDC_DNS" -ResourceGroupName $networkRG -TemplateURI $deployvnetwdns -TemplateParameterURI $parametersvnetdns2

#date
<#build CSR deployment, there are licensing issues if you don't prep the subscription for this;
  currently something isn't right with the PIP assignment, this takes 20-45 minutes#>
#New-AzureRmResourceGroupDeployment -Name "CSR_Deploy" -ResourceGroupName $networkRG -TemplateURI $deploycsr -TemplateParameterURI $parameterscsr
