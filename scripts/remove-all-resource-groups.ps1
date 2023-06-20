Get-AzSubscription -TenantId $TenantId | ForEach-Object -Parallel {
    Set-AzContext -SubscriptionId $_.Id
    $RGs = Get-AzResourceGroup
    $RGs | ForEach-Object -Parallel {
        Write-Host "Trying to remove the resource group: $($_.ResourceGroupName)"
        $_ | Remove-AzResourceGroup -Force -ErrorAction SilentlyContinue
        
        if (Get-AzResourceGroup -ResourceGroupName $_.ResourceGroupName -ErrorAction SilentlyContinue) {
            Write-Warning "Failed to remove resource group: $($_.ResourceGroupName). The job will fail at the end."
            $jobhasfailed = $true
        }
        else{
            Write-Host "Successfully removed resource group: $($_.ResourceGroupName)"
        }
        
    }
}

if ($jobhasfailed) {
    Write-Error "Failed to remove all resource groups. Re-run this workflow to try again."
}
