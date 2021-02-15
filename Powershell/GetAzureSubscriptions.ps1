#SOURCE: https://www.yobyot.com/powershell/azure-subscriptions/2019/10/01/
Function Get-ActiveAzSubscriptions { Get-AzSubscription | Where-Object -Property State -eq "Enabled" }
Set-Alias -Name activesubs -Value Get-ActiveAzSubscriptions
Function selectsub {activesubs | Out-GridView -PassThru | Select-AzSubscription}