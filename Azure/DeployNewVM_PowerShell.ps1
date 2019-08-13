# To install the AzureRM Module
Install-Module -Name AzureRM

# Variables
$LoginUserName="";
$LoginPassword="";
$ResourceGroupName="psdemo-rg";
$VNetName="psdemo-vnet-1";
$SubNetName="psdemo-subnet-1";
$NetworkPublicIPName="psdemo-windows-1-pip-1";
$NetworkSecurityGroupName="psedemo-windows-nsg-1";
$NicName="psdemo-windows-1-nic-1";
$VMName="psdemo-windows";
$ImageName="2016-Datacenter";
$MachineUserName="adminuser";
$MachinePassword="P.ass3040977"

# 1 - Login into Azure Account;
# Create a Credential Object
<#[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$SecurePsw = ConvertTo-SecureString $LoginPassword -AsPlainText -Force;
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($LoginUserName, $SecurePsw);#>
Connect-AzureRmAccount -Subscription "Visual Studio Test Professional"

# 2 - Create a Resource Group;
<#  To use an existing resource Group
$rgConfig = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location "centralus"
#>
$rgConfig = New-AzureRmResourceGroup -Name $ResourceGroupName -Location "centralus"

# 3 - Create Virtual Network (VNet) and Subnet
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubNetName -AddressPrefix "10.2.1.0/24";
$subnetConfig

$vnetConfig = New-AzureRmVirtualNetwork -ResourceGroupName $rgConfig.ResourceGroupName -Location "centralus" -Name $VNetName -AddressPrefix "10.2.0.0/16" -Subnet $subnetConfig
$vnetConfig

# 4 - Create Public IP Address;
$publicIPConfig = New-AzureRmPublicIpAddress -ResourceGroupName $rgConfig.ResourceGroupName -Location $rgConfig.Location -Name $NetworkPublicIPName -AllocationMethod Static
$publicIPConfig

# 5 - Create Network Security Group;
$networkSecurityRule = New-AzureRmNetworkSecurityRuleConfig -Name "RDPRule" -Description "Allow RDP" -Access Allow -Protocol TCP -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
$networkSecurityRule

$networkSecurityGroup = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgConfig.ResourceGroupName -Location $rgConfig.Location -Name $NetworkSecurityGroupName -SecurityRules $networkSecurityRule
$networkSecurityGroup | more

# 6 - Create a virtual network interface and associate with public IP address and Network Security Group;
$subnetConfig = $vnetConfi.Subnets #| Where-Object {$_.Name -eq $SubNetName}
$subnetConfig

$networkInterface = New-AzureRmNetworkInterface -ResourceGroupName $rgConfig.ResourceGroupName -Location $rgConfig.Location -Name $NicName -Subnet $subnetConfig -PublicIpAddress $publicIPConfig -NetworkSecurityGroup $networkSecurityGroup
$networkInterface

# 7 - Create a Virtual Machine
$windowsVmConfig = New-AzureRmVMConfig -VMName $VMName -VMSize "Standard_D1"
$vmPassword = ConvertTo-SecureString $MachinePassword -AsPlainText -Force
$vmCred = New-Object System.Management.Automation.PSCredential ($MachineUserName, $vmPassword)

$windowsVmConfig = Set-AzureRmVMOperatingSystem -VM $windowsVmConfig -Windows -ComputerName $VMName -Credential $vmCred

# This command lists the images available based on the publisher and offer;
#Get-AzureRmVMImageSku -Location "centralus" -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" 

$windowsVmConfig = Set-AzureRmVMSourceImage -VM $windowsVmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus $ImageName -Version "latest"

# Assing the Created Network Interface to the VM
$windowsVmConfig = Add-AzureRmVMNetworkInterface -VM $windowsVmConfig -Id $networkInterface.Id

# Create the Virtual Machine, passing in the VM Configuration
New-AzureRmVM -ResourceGroupName $rgConfig.ResourceGroupName -Location $rgConfig.Location -VM $windowsVmConfig

$myIp = Get-AzureRmPublicIpAddress -ResourceGroupName $rgConfig.ResourceGroupName -Name $publicIPConfig.Name | Select-Object -ExpandProperty
$myIp

New-AzureRmVM -Image Win2016Datacenter
$vmParams = @{
    ResourceGroupName = $ResourceGroupName
    Name = "psdemo-win-2"
    Location = "centralus"
    Size = "Standard_D1"
    Image = "Win2016Datacenter"
    $NetworkPublicIPName = "psdemo-win-2-pip-1"
    Credential = $vmCred
    VirtualNetworkName = "psdemo-vnet-2"
    SubnetName = "psdemo-subnet-2"
    SecurityGroupName = "psdemo-win-nsg-2"
    OpenPorts = 3389
}

New-AzureRmVM @vmParams