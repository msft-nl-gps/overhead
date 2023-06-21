$TRMG = Get-AzManagementGroup | where {$_.Name -like $_.TenantId}
Write-Host ("Tenant root management group: [{0} - {1}]" -f $TRMG.DisplayName, $TRMG.Id)

$AllMGs = Get-AzManagementGroup | where {$_.Name -notlike $TRMG.TenantId}
$AllMGs

ForEach ($MG in $AllMGs){
    Write-Host ("Removing policy assignments from management group: [{0} - {1}]" -f $MG.DisplayName, $MG.Id)
    $allPolicyAssignments = Get-AzPolicyAssignment -Scope $MG.Id
    foreach ($policyAssignment in $allPolicyAssignments){
        if ($policyAssignment.Properties.Scope -notlike $TRMG.Id){
            Write-Host ("Removing policy assignment [{0}] that contains the policy definition id: [{1}] at scope [{2}]" -f $policyAssignment.Properties.DisplayName, $policyAssignment.Properties.PolicyDefinitionId, $policyAssignment.Properties.Scope)
            Remove-AzPolicyAssignment -Id $policyAssignment.ResourceId -Confirm:$false -ErrorAction Continue
        }        
    }
}

Write-Host ("All policy assignments removed from all management groups except for the tenant root management group: [{0}]" -f $TRMG.Id)