$TRMG = Get-AzManagementGroup | where {$_.Name -like $_.TenantId}

$AllMGs = Get-AzManagementGroup | where {$_.Name -notlike $TRMG.te}
#$AllMGs

$AllMGs | Foreach-Object {
    $Assignments = Get-AzPolicyAssignment -Scope $_.Id | Select-Object -ExpandProperty properties
    foreach ($Assignment in $Assignments){
        if ($Assignment.Scope -notlike $TRMG.Id){
            Write-Host ("Removing policy assignment [{0}] that contains the policy definition id: [{1}] at scope [{2}]" -f $Assignment.DisplayName, $Assignment.PolicyDefinitionId, $Assignment.Scope)
            Remove-AzPolicyAssignment -Id $Assignment.Id -Force
        }
    }
}

Write-Host ("All policy assignments removed from all management groups except for the tenant root management group: [{0}]" -f $TRMG.Id)