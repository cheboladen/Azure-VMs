class Storage
{
    static [String] NewStorageAccount([String] $ResourceGroupName,[String] $StorageName, [String] $StorageSKU, [String] $Location)
    {
        return New-AzStorageAccount -ResourceGroupName $ResourceGroupName -Name $StorageName -SKUName $StorageSKU -Kind "Storage" -Location $Location   
    }
}

class Network
{
    static [String] SubnetConfig([String] $SubnetName, [String] $VNetSubnetAddressPrefix)
    {
        return New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $VNetSubnetAddressPrefix
    }

    static [String] VNet([String] $VNetName, [String] $ResourceGroupName, [String] $Location, [String] $VNetAddressPrefix, [String] $SubnetConfig)
    {
        return New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $VNetAddressPrefix -Subnet $SubnetConfig
    }

    static [String] PublicIp([String] $InterfaceName, [String] $ResourceGroupName, [String] $Location, [String] $TCPIPAllocationMethod)
    {
        return New-AzPublicIpAddress -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -AllocationMethod $TCPIPAllocationMethod -DomainNameLabel "$ResourceGroupName-dom"
    }

    static [String] NewNSGRule([String] $Rulename, [String] $Protocol, [String] $Direction, [String] $PortRange, [String] $Access)
    {
        return New-AzNetworkSecurityRuleConfig -Name $Rulename -Protocol $Protocol -Direction $Direction -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $PortRange -Access $Access
    }

    static [String] NewNSG([String] $NSGName, [String] $ResourceGroupName, [String] $Location, [String] $Rules)
    {
        return New-AzNetworkSecurityGroup -Name $NSGName -ResourceGroupName $ResourceGroupName -Location $Location -SecurityRules $Rules
    }

    static [String] NewInterface([String] $InterfaceName, [String] $ResourceGroupName, [String] $Location, [String] $VNet, [String] $PublicIp, [String] $NSG)
    {
        return New-AzNetworkInterface -Name $InterfaceName -ResourceGroupName $ResourceGroupName -Location $Location -SubnetId $VNet.Subnets[0].Id -PublicIpAddressId $PublicIp.Id -NetworkSecurityGroupId $NSG.Id
    }
}

class Automation
{   
    static [String] NewAccount([String] $AutomationAccount, [String] $Location, [String] $ResourceGroupName)
    {
        return New-AzAutomationAccount -Name $AutomationAccount -Location $Location -ResourceGroupName $ResourceGroupName
    }

    static [String] NewRunbook([String] $AutomationAccount, [String] $RunbookName, [String] $ResourceGroupName)
    {
        return New-AzAutomationRunbook -AutomationAccountName $AutomationAccount -Name $RunbookName -Type PowerShell -ResourceGroupName $ResourceGroupName
    }

    static [String] ImportRunbook([String] $AutomationAccount, [String] $RunbookName, [String] $ScriptPath, [String] $Type, [String] $ResourceGroupName)
    {
        return Import-AzAutomationRunbook -AutomationAccountName $AutomationAccount -Name $RunbookName -Path $ScriptPath -Type $Type -ResourceGroupName $ResourceGroupName –Force
    }  

    static [String] NewSchedule([String] $AutomationAccount, [String] $ScheduleName, [String] $StartTime, [String] $ResourceGroupName, [String] $TimeZone)
    {
        return New-AzAutomationSchedule -AutomationAccountName $AutomationAccount -Name $ScheduleName -StartTime $StartTime -DayInterval 1 -ResourceGroupName $ResourceGroupName -TimeZone $TimeZone 
    }  
}

    Function CreateAzVMs {
        [cmdletbinding()]
        param ([parameter(ValueFromPipeline)] [String] $File)
    
        Import-Csv $File | ForEach-Object {
        $InterfaceName = $_.ResourceGroupName + "iface"
        $ComputerName = $_.ResourceGroupName + "server"
        $VNetName = $_.ResourceGroupName + "vnet"
        $StorageName = $_.ResourceGroupName + "storg"
        $Rulename = $_.ResourceGroupName + "inbound"
        $NSGName = $_.ResourceGroupName + "nsg"

        New-AzResourceGroup -Name $_.ResourceGroupName -Location $_.Location

        $VirtualMachine = New-AzVMConfig -VMName $_.VMName -VMSize $_.VMSize
    
        $VirtualMachine = Set-AzVMOperatingSystem -VM $VirtualMachine -Windows -ComputerName $ComputerName -Credential $VMCredential -ProvisionVMAgent -EnableAutoUpdate
    
        $SubnetConfig = [Network]::SubnetConfig($_.SubnetName,$_.VNetSubnetAddressPrefix)
        $VNet = [Network]::VNet($VNetName,$_.ResourceGroupName,$_.Location,$_.VNetAddressPrefix,$SubnetConfig)
        $PublicIp = [Network]::PublicIp($InterfaceName,$_.ResourceGroupName,$_.Location,$_.TCPIPAllocationMethod)
        $NewNSGRule = [Network]::NewNSGRule($Rulename,"TCP","Inbound",$_.DestinationPortRange,"Allow")
        $NewNSG = [Network]::NewNSG($NSGName,$_.ResourceGroupName,$_.Location,$NewNSGRule)
        $Interface =  [Network]::NewInterface($InterfaceName,$_.ResourceGroupName,$_.Location,$VNet,$PublicIp,$NewNSG)
        $VirtualMachine = Add-AzVMNetworkInterface -VM $VirtualMachine -Id $Interface.Id
    
        $OSDiskName = $_.ResourceGroupName + "osdisk"
        $StorageAccount = [Storage]::NewStorageAccount($_.ResourceGroupName,$StorageName,$_.StorageSKU,$_.Location)
        $OSDiskUri = $StorageAccount.PrimaryEndpoints.Blob.ToString() + "vhds/" + $OSDiskName + ".vhd"
        $VirtualMachine = Set-AzVMOSDisk -VM $VirtualMachine -Name $OSDiskName -VhdUri $OSDiskUri -Caching ReadOnly -CreateOption FromImage
    
        $VirtualMachine = Set-AzVMSourceImage -VM $VirtualMachine -PublisherName $_.PublisherName -Offer $_.OfferName -SKUs $_.SKU -Version $_.Version        
        New-AzVM -ResourceGroupName $_.ResourceGroupName -Location $_.Location -VM $VirtualMachine
        New-AzSqlVM -ResourceGroupName $_.ResourceGroupName -Name $_.VMName -Location $_.Location -LicenseType PAYG
        }
    }




# $AutomationAccount = "automata"
# $ResourceGroupName = "test"
# $RunbookName = "apagado"

# [Automation]::NewAccount($AutomationAccount,"eastus",$ResourceGroupName)

# [Automation]::NewRunbook($AutomationAccount,$RunbookName,$ResourceGroupName)

# [Automation]::ImportRunbook($AutomationAccount,$RunbookName,".\Apagado.ps1",$ResourceGroupName)

# [Automation]::NewSchedule($AutomationAccount,"Apppaga","18:00",$ResourceGroupName,"Romance Standard Time")