# Variables
Import-Module Az.Compute
Import-Module Az.Network
Import-Module Az.Storage
Import-Module Az.Resources
Import-Module Az.Automation

## Azure Login
$AzCredential = Get-Credential -Message "Type the name and password of the Azure account."
Connect-AzAccount -Credential $AzCredential

## Global
$Location = "eastus"
$ResourceGroupName = "tost"
$TimeZone = ([System.TimeZoneInfo]::Local).Id
$AutomationAccount = "automate"
$RunbookName = "apagate"

## Storage
$StorageName = $ResourceGroupName + "storg"
$StorageSKU = "Premium_LRS"

## Network
$InterfaceName = $ResourceGroupName + "iface"
$NSGName = $ResourceGroupName + "nsg"
$VNetName = $ResourceGroupName + "vnet"
$SubnetName = "Default"
$VNetAddressPrefix = "10.0.0.0/16"
$VNetSubnetAddressPrefix = "10.0.0.0/24"
$TCPIPAllocationMethod = "Dynamic"
$DomainName = $ResourceGroupName

## Compute
$VMName = $ResourceGroupName + "vm"
$ComputerName = $ResourceGroupName + "server"
$VMSize = "Standard_B1s"
$OSDiskName = $VMName + "OSDisk"

## Image
$PublisherName = "MicrosoftSQLServer"
$OfferName = "SQL2017-WS2016"
$SKU = "SQLDEV"
$Version = "latest"

## Local Login
$VMLocalAdminUser = "Fer"
$VMLocalAdminSecurePassword = ConvertTo-SecureString "Pa55word" -AsPlainText -Force
$VMCredential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

# Resource Group
New-AzResourceGroup -Name $ResourceGroupName -Location $Location

# Storage
$StorageAccount = New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -SKUName $StorageSKU -Kind "Storage" -Location $Location

# Network
$SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
$VNet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
$PublicIp = New-AzPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod $TCPIPAllocationMethod -DomainNameLabel "$DomainName-dom"
$NSGRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
$NSGRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow
$NSG = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $Location -Name $NSGName -SecurityRules $NSGRuleRDP,$NSGRuleSQL
$Interface = New-AzNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIp.Id -NetworkSecurityGroupId $NSG.Id

# Compute
$VirtualMachine = New-AzVMConfig -VMName $VMName -VMSize $VMSize
$VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $VMCredential -ProvisionVMAgent -EnableAutoUpdate
$VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
$OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
$VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching ReadOnly -CreateOption FromImage

# Image
$VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $PublisherName -Offer $OfferName -SKUs $SKU -Version $Version

# Create the VM in Azure
New-AzVM -ResourceGroupName $ResourceGroupName -Location $Location -VM $VirtualMachine

# Add the SQL IaaS Extension, and choose the license type
New-AzSqlVM -ResourceGroupName $ResourceGroupName -Name $VMName -Location $Location -LicenseType PAYG

# Create Azure Automation Account
New-AzAutomationAccount -Name $AutomationAccount -Location $Location -ResourceGroupName $ResourceGroupName

# Create an Automation runbook.
New-AzAutomationRunbook -AutomationAccountName $AutomationAccount -Name $RunbookName -Type PowerShell -ResourceGroupName $ResourceGroupName

# Add VM to Apagado script
Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName | Out-File ".\Apagado.ps1" -Append

# Import an Automation runbook.
Import-AzAutomationRunbook -AutomationAccountName $AutomationAccount -Name $RunbookName -Path ".\Apagado.ps1" -Type PowerShell -ResourceGroupName $ResourceGroupName -Force
  
# Create Shutdown Schedule
New-AzAutomationSchedule -AutomationAccountName $AutomationAccount -Name "$($RunbookName)sched" -StartTime "18:00" -DayInterval 1 -ResourceGroupName $ResourceGroupName -TimeZone $TimeZone