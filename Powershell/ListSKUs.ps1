#SOURCE: https://www.yobyot.com/powershell/find-windows-azure-vm-images-using-powershell/2019/12/17/

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]
    $location = "eastus"
)
$pubs = Get-AzVMImagePublisher -Location $location | Select-Object PublisherName | Out-GridView -PassThru
$offers = $pubs | ForEach-Object {Get-AzVMImageOffer -Location $location -PublisherName $_.PublisherName}  | Out-GridView -PassThru
$skus = $offers | ForEach-Object {Get-AzVmImageSku -Location $location -PublisherName $_.PublisherName -Offer $_.Offer}
$versions = $skus | ForEach-Object {Get-AzVMImage -Location $location -PublisherName $_.PublisherName -Offer $_.Offer -Skus $_.Skus}
$output = $versions | Out-GridView -PassThru | Select-Object -Property Version,Skus,Offer,PublisherName,Location,Id 
$output | Export-Csv "$HOME/Desktop/AzureVmOffers.csv"
$output | Sort-Object -Property Skus | Format-Table -GroupBy Skus 