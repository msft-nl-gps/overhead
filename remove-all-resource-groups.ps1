Get-AzSubscription -TenantId $TenantId | ForEach-Object { 
    Set-AzContext -SubscriptionId $_.Id
    foreach ($rg in Get-AzResourceGroup)    {   
        Write-Host "Removing resource group: $($rg.ResourceGroupName)"
        Remove-AzResourceGroup -Force
    }
}
