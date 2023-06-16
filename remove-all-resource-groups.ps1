Get-AzSubscription -TenantId $TenantId | ForEach-Object { 
    Set-AzContext -SubscriptionId $_.Id
    foreach ($rg in Get-AzResourceGroup)    {   
        Write-Host "Removing resource group: $($rg.ResourceGroupName)"
        try{Remove-AzResourceGroup $rg.ResourceGroupName -Force}
        catch{}
    }
}
