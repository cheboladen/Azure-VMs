#SOURCE: https://www.manuelmeyer.net/2020/06/azure-tip-7-bulk-deleting-and-purging-azure-resource-groups/

#Use a filter to select resource groups by substring
$filter = 'SQL'
 
#Find Resource Groups by Filter -> Verify Selection
Get-AzResourceGroup | Where-Object ResourceGroupName -match $filter | Select-Object ResourceGroupName
 
#Async Delete ResourceGroups by Filter. Uncomment the following line if you understand what you are doing. :-)
#Get-AzResourceGroup | Where-Object ResourceGroupName -match $filter | Remove-AzResourceGroup -AsJob -Force