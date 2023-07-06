param(
    [Parameter(Mandatory = $true)][securestring]$passwordPrefix,
    [Parameter(Mandatory = $false)][string]$maxNumberOfParticipants = 25,
    [Parameter(Mandatory = $false)][string]$domain = '@mngenvmcap168626.onmicrosoft.com',
    [Parameter(Mandatory = $false)][string]$roleAssignmentGroupId = '75a3feb5-db44-4442-9d71-82826c19c56f',
    [Parameter(Mandatory = $false)][string]$graphApiVersion = 'beta',
    [Parameter(Mandatory = $false)][string]$usageLocation = 'NL'
)

Write-Host "Provisioning hackathon participants..."
Write-Host "Assign role and license using group membership..."

# Get Authentication token for the graph API
# Permissions needed: Directory.ReadWrite.All, RoleManagement.ReadWrite.Directory, RoleManagement.ReadWrite.Directory.AccessAsUser.All
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Host ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

#$userResource = "users"
#$groupResource = "groups"
$baseUriUser = "https://graph.microsoft.com/" + $graphApiVersion + "/users"
$baseUriGroup = "https://graph.microsoft.com/" + $graphApiVersion + "/groups"
# Pay attention to the backtick (`) in the URI below. This is required to escape the $ref character in the URI.
$uriGroupMembers = $baseUriGroup + "/" + $roleAssignmentGroupId +"/members/" + "`$ref"
$password = $(ConvertFrom-SecureString $passwordPrefix -AsPlainText) + $(Get-Date -Format yyyyMMdd) + '!'


if (Invoke-RestMethod -Uri $baseUriGroup -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Get) {

    for ($i = 1; $i -le $maxNumberOfParticipants; $i++) {
        Write-Output ("Processing user: [{0}] ..." -f $i)
        $body = @{
            accountEnabled    = $true
            displayName       = $("Hackathon Participant " + $i)
            mailNickname      = $("hackathon" + '-' + $i)
            userPrincipalName = $("hackathon" + '-' + $i + $domain)
            passwordProfile   = @{
                forceChangePasswordNextSignIn = $true
                password                      = "$password"
            }
            usageLocation     = $usageLocation
        }

        $user = Invoke-RestMethod -Uri $baseUriUser -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $($body | ConvertTo-Json)
        Write-Warning ("Created user: [{0}]" -f $user.userPrincipalName)

        $bodyUser = @{
            "@odata.id" = "https://graph.microsoft.com/$graphApiVersion/directoryObjects/$($user.id)"
        } 

        Invoke-RestMethod -Uri $uriGroupMembers -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $($bodyUser | ConvertTo-Json)
        Write-Warning ("User: [{0}] with id [{1}] and UPN: [{2}] added to group [{3}] for licensing and role assingment" -f $user.displayName, $user.id, $user.userPrincipalName, $roleAssignmentGroupId)
        $body = $null
        $user = $null
        $bodyUser = $null         
    }

    $bodyRoleAssignment = @{    
        action           = "AdminAssign"
        justification    = "Assign Hackathon user permissions via PIM for the duration of the hackathon"
        roleDefinitionId = "62e90394-69f5-4237-9190-012177145e10"
        directoryScopeId = "/"
        principalId      = $roleAssignmentGroupId
        scheduleInfo     = @{
            startDateTime = "2023-07-15T00:00:00Z"
            expiration    = @{
                endDateTime = "2023-07-16T00:00:00Z"
                type        = "AfterDateTime"
            }
        }
    }

    Invoke-RestMethod -Uri "https://graph.microsoft.com/" + $graphApiVersion + "/roleManagement/directory/roleEligibilityScheduleRequests" -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $($bodyRoleAssignment | ConvertTo-Json -Depth 3)
    $bodyRoleAssignment = $null
}
else {
    Write-Warning ("Provisioning has stopped. Group for licensing and permissions with id [{0}] could not be found." -f $roleAssignmentGroupId)
}
Write-Host "Done provisioning hackathon participants!"