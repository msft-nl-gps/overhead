Get-AzSubscription -TenantId $TenantId | ForEach-Object { 
    Set-AzContext -SubscriptionId $_.Id
    Get-AzResourceGroup | Remove-AzResourceGroup -Force
}