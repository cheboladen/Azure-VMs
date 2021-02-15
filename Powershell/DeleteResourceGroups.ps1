#Use a filter to select resource groups by substring
$filter = 'P*'
 
#Find Resource Groups by Filter -> Verify Selection
Get-AzResourceGroup | Where-Object ResourceGroupName -match $filter | Select-Object ResourceGroupName
 
#Async Delete ResourceGroups by Filter. Uncomment the following line if you understand what you are doing. :-)
#Get-AzResourceGroup | Where-Object ResourceGroupName -match $filter | Remove-AzResourceGroup -AsJob -Force