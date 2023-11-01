
Write-Output "Removing all unmanaged groups..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Output ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$api_resource = "groups"

$managedGroups = Get-Content -Path ../organization/groups.json | ConvertFrom-Json
Write-Output ("Found: [{0}] Managed Groups..." -f $managedGroups.Count)

$uri = "https://graph.microsoft.com/$graphApiVersion/$($api_resource)"

$allAADGroups = Invoke-RestMethod -Uri $uri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method Get
$allGroups = $allAADGroups.value
Write-Output ("Found: [{0}] Entra Groups..." -f $allGroups.Count)

function removeAnyLicenseFromGroup ($group) {
    $queryUri = "https://graph.microsoft.com/$graphApiVersion/$($api_resource)/$($group.id)?select=assignedLicenses"
    $postUri = "https://graph.microsoft.com/$graphApiVersion/$($api_resource)/$($group.id)/assignLicense"
    $assignedLicensesGroupInfo = Invoke-RestMethod -Uri $queryUri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method GET
    if ($assignedLicensesGroupInfo.assignedLicenses) {
        Write-Output ("Removing licenses from group [{0}] with id [{1}]..." -f $group.displayName, $group.id)
        $body = @{
            addLicenses    = @()
            removeLicenses = @($assignedLicensesGroupInfo.assignedLicenses.skuId)
        }
        $jsonBody = ConvertTo-Json $body
        $licenseRemovalOutput = Invoke-RestMethod -Uri $postUri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method POST -Body $jsonBody -ContentType "application/json"
        if ($licenseRemovalOutput.error) {
            Write-Output ("Error removing licenses from group [{0}] with id [{1}]..." -f $group.displayName, $group.id)
            Write-Output $licenseRemovalOutput.error
        }
        else {
            Write-Output ("Removed licenses from group [{0}] with id [{1}]..." -f $group.displayName, $group.id)
        }
    }
    
}

function removeEntraGroup ($group) {
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($api_resource)/$($group.id)"
    Write-Output ("Performing DELETE action on group [{0}] with id [{1}]..." -f $group.displayName, $group.id)
    removeAnyLicenseFromGroup -group $group
    Invoke-RestMethod -Uri $uri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method Delete
    Write-Output ("REMOVED group [{0}] with id [{1}]..." -f $group.displayName, $group.id)
}

foreach ($aadGroup in $allGroups) {
    Write-Output ("Processing Group: [{0}] with id [{1}]..." -f $aadGroup.displayName, $aadGroup.id)
    if ($aadGroup.displayName -in $managedGroups.displayName) {
        if (($managedGroups | Where-Object { $_.displayName -like $aadGroup.displayName }).Flags.doNotRemove) {
            Write-Verbose ("Skipping Managed Group: [{0}] with id [{1}]..." -f $aadGroup.displayName, $aadGroup.id) -Verbose
        }
        else {
            Write-Verbose ("Removing Managed Group: [{0}] with id [{1}]..." -f $aadGroup.displayName, $aadGroup.id) -Verbose
        }        
    }
    else {
        Write-Output ("Removing non-managed Group: [{0}] with id [{1}]..." -f $aadGroup.displayName, $aadGroup.id)
        removeEntraGroup -group $aadGroup
    }    
}