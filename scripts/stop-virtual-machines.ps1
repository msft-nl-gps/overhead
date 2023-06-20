Get-AzSubscription -TenantId $TenantId | ForEach-Object {
    Set-AzContext -SubscriptionId $_.Id
    $VMs = Get-AzVM
    $VMs | ForEach-Object -Parallel {
        try{
            Write-Host "Trying to stop the VM: $($_.Name)"
            Stop-AzVM $_ -Force
            Write-Host "Successfully stopped the VM: $($_.Name)"
        }
        catch{
            Write-Warning "Failed to stop VM: $($_.Name)"
        }
    }
}