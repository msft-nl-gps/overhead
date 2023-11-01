param(
    #[Parameter(Mandatory = $true)][securestring]$passwordPrefix,
    [Parameter(Mandatory = $false)][string]$domain = '@mngenvmcap168626.onmicrosoft.com',
    [Parameter(Mandatory = $false)][string]$usageLocation = 'NL'
)

Write-Output "Creating all users and groups..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Output ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$users_api_resource = "users"
$groups_api_resource = "groups"

$managedGroups = Get-Content -Path ../organization/groups.json | ConvertFrom-Json
$managedUsers = Get-Content -Path ../organization/users.json | ConvertFrom-Json

function provisionGroup ($group){
    Write-Output ("Processing group: [{0}] ..." -f $group)
    $entraGroupToProvision = $managedGroups | Where-Object { $_.displayName -like $group }
    Write-Output ("Checking if group [{0}] exists..." -f $entraGroupToProvision.displayName)
    $groupExists = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $groups_api_resource) -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method GET
    if (-not $groupExists){
        Write-Output ("Group [{0}] does not exist. Creating..." -f $entraGroupToProvision.displayName)
        $body = @{
            displayName = $entraGroupToProvision.displayName
            securityEnabled = $true
        }
        $createdGroup = Invoke-RestMethod -Uri $("https://graph.microsoft.com/" + $graphApiVersion + "/" + $groups_api_resource) -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -ContentType 'application/json' -Method POST -Body $($body | ConvertTo-Json)
        Write-Output ("Created group: [{0}] with id: [{1}]" -f $createdGroup.displayName, $createdGroup.id)
    }
    else {
        Write-Output ("Group [{0}] already exists. Skipping..." -f $entraGroupToProvision.displayName)
    
    }
}

function provisionUser ($user){
    Write-Output ("Processing user: [{0}] ..." -f $user.displayName)
    foreach ($securityGroupToProvision in $user.SecurityGroups){
        provisionGroup -group $securityGroupToProvision
    }
    

}

foreach ($managedUser in $managedUsers){
    provisionUser -user $managedUser

}