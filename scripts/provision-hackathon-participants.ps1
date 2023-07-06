Write-Host "Provisioning hackathon participants..."
Write-Host "Assign role and license using group membership..."


$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"

Write-Host ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$userResource = "users"
$groupResource = "groups"

$domain = "@mngenvmcap168626.onmicrosoft.com"
$uriUser = "https://graph.microsoft.com/$graphApiVersion/$($userResource)"
$roleAssignmentGroupId = "75a3feb5-db44-4442-9d71-82826c19c56f"
# Pay attention to the backtick (`) in the URI below. This is required to escape the $ref character in the URI.
$uriGroup = "https://graph.microsoft.com/$graphApiVersion/$($groupResource)/$($roleAssignmentGroupId)/members/" + "`$ref"
$password = $passwordPrefix + $(Get-Date -Format yyyyMMdd) + '!'


if(Invoke-RestMethod -Uri "https://graph.microsoft.com/$graphApiVersion/$($groupResource)" -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Get){

    for ($i = 111; $i -le 120; $i++) {
        Write-Output ("Processing user: [{0}] ..." -f $i)
        $body = @{
            accountEnabled    = $true
            displayName       = "Hackathon Participant $($i)"
            mailNickname      = "hackathon-$($i)"
            userPrincipalName = "hackathon-$($i)$domain"
            passwordProfile   = @{
                forceChangePasswordNextSignIn = $true
                password                      = "$password"
            }
            usageLocation     = "NL"
        }| ConvertTo-Json

        $user = Invoke-RestMethod -Uri $uriUser -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $body
        Write-Warning ("Created user: [{0}]" -f $user.userPrincipalName)

        $bodyUser = @{
            "@odata.id" = "https://graph.microsoft.com/$graphApiVersion/directoryObjects/$($user.id)"
        } | ConvertTo-Json

        Invoke-RestMethod -Uri $uriGroup -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $bodyUser
        Write-Warning ("User: [{0}] with id [{1}] and UPN: [{2}] added to group [{3}] for licensing and role assingment" -f $user.displayName, $user.id, $user.userPrincipalName, $roleAssignmentGroupId)         
    }
    $bodyRoleAssignment = @{    
        action                = "AdminAssign"
        justification         = "Assign Hackathon user permissions via PIM for the duration of the hackathon"
        roleDefinitionId      = "62e90394-69f5-4237-9190-012177145e10"
        directoryScopeId      = "/"
        principalId           = $roleAssignmentGroupId
        scheduleInfo          = @{
            startDateTime     = "2023-07-15T00:00:00Z"
            expiration        = @{
                endDateTime   = "2023-07-16T00:00:00Z"
                type          = "AfterDateTime"
                }
            }
    } | ConvertTo-Json -Depth 3

    Invoke-RestMethod -Uri "https://graph.microsoft.com/$graphApiVersion/roleManagement/directory/roleEligibilityScheduleRequests" -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $bodyRoleAssignment
   

}else{
    Write-Warning ("Provisioning has stopped. Group for licensing and permissions with id [{0}] could not be found." -f $roleAssignmentGroupId)
}
Write-Host "Done provisioning hackathon participants!"


