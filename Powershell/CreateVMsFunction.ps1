function CreateAzVMs {
    param (
        [parameter(ValueFromPipeline)] 
        [String] $File
    )

    Import-Module Az.Compute
    Import-Module Az.Network
    Import-Module Az.Storage
    Import-Module Az.Resources
    Import-Module Az.Automation
    
    ## Azure Login
    $AzCredential = Get-Credential -Message "Type the name and password of the Azure account."
    Connect-AzAccount -Credential $AzCredential

    Import-Csv $File | ForEach-Object {
        # Variables

        ## Storage
        $StorageName = $_.ResourceGroupName + "storg"

        ## Compute
        $ComputerName = $_.ResourceGroupName + "server"
        $OSDiskName = $_.VMName + "OSDisk"

        ## Network
        $InterfaceName = $_.VMName + "iface"
        $NSGName = $_.ResourceGroupName + "nsg"
        $VNetName = $_.ResourceGroupName + "vnet"
        $DomainName = $_.ResourceGroupName + "-dom"

        ## Local Login
        $VMLocalAdminUser = "Fer"
        $VMLocalAdminSecurePassword = ConvertTo-SecureString "Pa55word" -AsPlainText -Force
        $VMCredential = New-Object System.Management.Automation.PSCredential ($VMLocalAdminUser, $VMLocalAdminSecurePassword);

        # Resource Group
        New-AzResourceGroup -Name $_.ResourceGroupName -Location $_.Location

        # Storage
        $StorageAccount = New-AzStorageAccount -ResourceGroupName $_.ResourceGroupName -Name $StorageName -SKUName $_.StorageSKU -Kind "Storage" -Location $_.Location

        # Network
        $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $_.SubnetName -AddressPrefix $_.VNetSubnetAddressPrefix
        $VNet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $_.ResourceGroupName -Location $_.Location -AddressPrefix $_.VNetAddressPrefix -Subnet $SubnetConfig
        $PublicIp = New-AzPublicIpAddress -Name $InterfaceName -ResourceGroupName $_.ResourceGroupName -Location $_.Location -AllocationMethod $_.TCPIPAllocationMethod -DomainNameLabel "$DomainName-dom"
        $NSGRuleRDP = New-AzNetworkSecurityRuleConfig -Name "RDPRule" -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow
        $NSGRuleSQL = New-AzNetworkSecurityRuleConfig -Name "MSSQLRule"  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 1433 -Access Allow
        $NSG = New-AzNetworkSecurityGroup -ResourceGroupName $_.ResourceGroupName -Location $_.Location -Name $NSGName -SecurityRules $NSGRuleRDP,$NSGRuleSQL
        $Interface = New-AzNetworkInterface -Name $InterfaceName -ResourceGroupName $_.ResourceGroupName -Location $_.Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIp.Id -NetworkSecurityGroupId $NSG.Id

        # Compute
        $VirtualMachine = New-AzVMConfig -VMName $_.VMName -VMSize $_.VMSize
        $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $VMCredential -ProvisionVMAgent -EnableAutoUpdate
        $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
        $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
        $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching ReadOnly -CreateOption FromImage

        # Image
        $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $_.PublisherName -Offer $_.OfferName -SKUs $_.SKU -Version $_.Version

        # Create the VM in Azure
        New-AzVM -ResourceGroupName $_.ResourceGroupName -Location $_.Location -VM $VirtualMachine

        # Add the SQL IaaS Extension, and choose the license type
        New-AzSqlVM -ResourceGroupName $_.ResourceGroupName -Name $_.VMName -Location $_.Location -LicenseType PAYG

        # Create Azure Automation Account
        New-AzAutomationAccount -Name $_.AutomationAccount -Location $_.Location -ResourceGroupName $_.ResourceGroupName

        # Create an Automation runbook
        New-AzAutomationRunbook -AutomationAccountName $_.AutomationAccount -Name "Apagado" -Type PowerShell -ResourceGroupName $_.ResourceGroupName

        # Add VM to Apagado script
        "Stop-AzVM -ResourceGroupName $($_.ResourceGroupName) -Name $($_.VMName)" | Out-File ".\Apagado.ps1" -Append

        # Import an Automation runbook.
        Import-AzAutomationRunbook -AutomationAccountName $_.AutomationAccount -Name "Apagado" -Path ".\Apagado.ps1" -Type PowerShell -ResourceGroupName $_.ResourceGroupName –Force
        
        # Create Shutdown Schedule
        New-AzAutomationSchedule -AutomationAccountName $_.AutomationAccount -Name "Apagadosched" -StartTime "18:00" -DayInterval 1 -ResourceGroupName $_.ResourceGroupName -TimeZone $_.TimeZone
    }
}