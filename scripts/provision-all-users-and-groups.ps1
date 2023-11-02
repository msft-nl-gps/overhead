param(
    [Parameter(Mandatory = $true)][securestring]$passwordPrefix,
    [Parameter(Mandatory = $false)][string]$domain = 'mngenvmcap168626.onmicrosoft.com',
    [Parameter(Mandatory = $false)][string]$usageLocation = 'NL'
)

$password = $(ConvertFrom-SecureString $passwordPrefix -AsPlainText) + $(Get-Date -Format yyyyMMdd) + '!'

Write-Output "Creating all users and groups..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Output ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$users_api_resource = "users"
$groups_api_resource = "groups"

$managedGroups = Get-Content -Path ../organization/groups.json | ConvertFrom-Json
$managedUsers = Get-Content -Path ../organization/users.json | ConvertFrom-Json

function provisionGroup ($group) {
    #use write-host only inside functions to output to the console
    Write-Host ("Processing group: [{0}] ..." -f $group)
    $entraGroupToProvision = $managedGroups | Where-Object { $_.displayName -like $group }
    Write-Host ("Checking if group [{0}] exists..." -f $entraGroupToProvision.displayName)
    $groupExists = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $groups_api_resource + '?$filter=startswith(displayName,' + "'" + $entraGroupToProvision.displayName + "'" + ')') -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method GET
    if (-not $groupExists.value) {
        Write-Host ("Group [{0}] does not exist. Creating..." -f $entraGroupToProvision.displayName)
        $body = @{
            displayName     = $entraGroupToProvision.DisplayName
            mailEnabled     = $false
            mailNickname    = $entraGroupToProvision.DisplayName
            securityEnabled = $true
        }
        $createdGroup = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $groups_api_resource) -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method POST -Body $($body | ConvertTo-Json)
        Write-Host ("Created group: [{0}] with id: [{1}]" -f $createdGroup.displayName, $createdGroup.id)
        return $createdGroup
    }
    else {
        Write-Host ("Group [{0}] already exists. Skipping..." -f $entraGroupToProvision.displayName)
        return $groupExists.value[0]
    
    }
}

function provisionUser ($user) {
    Write-Host ("Processing user: [{0}] ..." -f $user.displayName)

    $upn = $($user.mailNickName + '@' + $domain)
    Write-Host ("Checking if user [{0}] exists..." -f $upn)
    $userExists = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $users_api_resource + '?$filter=startswith(userPrincipalName,' + "'" + $upn + "'" + ')') -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method GET

    if ($userExists.value) {
        Write-Host ("User [{0}] already exists. Skipping..." -f $upn)
        return $userExists.value[0]
    }
    else {
        Write-Host ("User [{0}] does not exist. Creating..." -f $upn)
        $body = @{
            accountEnabled    = $true
            displayName       = $user.DisplayName
            mailNickname      = $user.mailNickName
            userPrincipalName = $upn
            passwordProfile   = @{
                forceChangePasswordNextSignIn = $true
                password                      = "$password"
            }
            usageLocation     = $usageLocation
        }
        $createdUser = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $users_api_resource)  -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method Post -Body $($body | ConvertTo-Json)
        Write-Host ("Created user: [{0}]" -f $createdUser.userPrincipalName)
        return $createdUser
    }    
}

function ensureUserIsMemberOfGroup ($user, $group) {
    Write-Host ("Checking if user [{0}] is member of group [{1}]..." -f $user.userPrincipalName, $group.displayName)
    $groupMembers = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $groups_api_resource + "/" + $group.id + "/" + "members") -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method GET

    $userIsMemberOfGroup = $groupMembers.value | Where-Object { $_.id -eq $user.id }
    if ($userIsMemberOfGroup) {
        Write-Host ("User [{0}] is already member of group [{1}]. Skipping..." -f $user.userPrincipalName, $group.displayName)
    }
    else {
        Write-Host ('User [{0}] is not member of group [{1}]. Adding user...' -f $user.userPrincipalName, $group.displayName)
        $body = @{
            "@odata.id" = $("https://graph.microsoft.com/" + $graphApiVersion + "/directoryObjects/" + $user.id)
        }
        Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $groups_api_resource + "/" + $group.id + "/" + "members" + "/" + "$" + "ref") -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method POST -Body $($body | ConvertTo-Json)
        Write-Host ('Added user [{0}] to group [{1}]' -f $user.userPrincipalName, $group.displayName)

    }
    
}

foreach ($managedUser in $managedUsers) {
    Write-Output "-----------------------------------------------------------------------------------------"
    # create the user
    $provisionedUser = provisionUser -user $managedUser

    # create any needed security groups
    $provisionedUserGroups = @()
    foreach ($securityGroupToProvision in $managedUser.SecurityGroups) {
        $provisionedUserGroups += provisionGroup -group $securityGroupToProvision
    }

    # ensure user is member of group
    foreach ($provisionedUserGroup in $provisionedUserGroups) {
        ensureUserIsMemberOfGroup -user $provisionedUser -group $provisionedUserGroup
    }
}