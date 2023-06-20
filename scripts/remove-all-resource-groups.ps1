Get-AzSubscription -TenantId $TenantId | ForEach-Object -Parallel {
    Set-AzContext -SubscriptionId $_.Id
    $RGs = Get-AzResourceGroup
    $RGs | ForEach-Object -Parallel {
        try{
            Write-Host "Trying to remove the resource group: $($_.ResourceGroupName)"
            $_ | Remove-AzResourceGroup -Force
            Write-Host "Successfully removed the resource group: $($_.ResourceGroupName)"
        }
        catch{
            Write-Warning "Failed to remove resource group: $($_.ResourceGroupName)"
        }
    }
}