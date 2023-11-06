$HackathonDurationInDays = 1
$graphApiVersion = "beta"

$ManagementGroups = ConvertFrom-Json -InputObject (Get-Content -Path "../organization/management-groups-and-subscriptions.json" -Raw)
$GroupsEntitlements = ConvertFrom-Json -InputObject (Get-Content -Path "../organization/groups.json" -Raw)

$ManagementGroups
$GroupsEntitlements


$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Output ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)


function getEntraGroupByName ($groupName) {
    Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/groups" + '?$filter=startswith(displayName,' + "'" + $groupName + "'" + ')') `
        -Headers @{'Authorization' = 'Bearer ' + $authToken.token } `
        -ContentType 'application/json' `
        -Method GET
}

function processEntraRole ($groupName, $role) {
    $groupId = (getEntraGroupByName $groupName).value[0].id

    if ($role.DurationInDays -eq 0) {     
        $bodyRoleAssignment = @{    
            action           = "AdminAssign"
            justification    = "Hackathon Provisioning - Automated pipeline"
            roleDefinitionId = $role.templateId
            appScopeId       = "/"
            directoryScopeId = "/"
            principalId      = $groupId
            scheduleInfo     = @{
                startDateTime = Get-Date
                expiration    = @{
                    type = "noExpiration"
                }
            }   
        }
    }
    else {
        $bodyRoleAssignment = @{    
            action           = "AdminAssign"
            justification    = "Hackathon Provisioning - Automated pipeline"
            roleDefinitionId = $role.templateId
            appScopeId       = "/"
            directoryScopeId = "/"
            principalId      = $groupId
            scheduleInfo     = @{
                startDateTime = Get-Date
                expiration    = @{
                    endDateTime = (Get-Date).AddDays($HackathonDurationInDays)
                    type        = "AfterDateTime"
                }
            }
        }
    }


    Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/roleManagement/directory/roleEligibilityScheduleRequests") `
        -Headers @{'Authorization' = 'Bearer ' + $authToken.token } `
        -ContentType 'application/json' `
        -Method Post `
        -Body $($bodyRoleAssignment | ConvertTo-Json -Depth 3)
}

foreach ($group in $GroupsEntitlements) {
    Write-Output("------------------------------------------------------")
    Write-Output ("Processing permissions for group {0}" -f $group.DisplayName)
    if ($group.EntraRoles) {
        Write-Output ("Entra Roles found for group {0}" -f $group.DisplayName)
        foreach ($role in $group.EntraRoles) {
            Write-Output ("Processing role [{0}] with template Id [{1}]" -f $role.Name, $role.TemplateId)
            processEntraRole $group.DisplayName $role
        }
    }
    else {
        Write-Output ("No Entra Roles found for group [{0}]" -f $group.DisplayName)
    }
    if ($group.AzureResourcesRoles) {
        Write-Output ("Azure Resources Roles found for group [{0}]" -f $group.DisplayName)
    }
    else {
        Write-Output ("No Azure Resources Roles found for group [{0}]" -f $group.DisplayName)
    }
}