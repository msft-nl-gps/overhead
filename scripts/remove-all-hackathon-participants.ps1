Write-Host "Removing all hackathon participants..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Host ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$User_resource = "users"

$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
Write-Verbose $uri
$allAADUsers = Invoke-RestMethod -Uri $uri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method Get

$allUsers = $allAADUsers.value
Write-Host "Processing [$($allUsers.Count)] users..."

foreach ($aadUser in $allUsers)  {
    Write-Host ("Processing user: [{0}] with id [{1}]..." -f $aadUser.displayName, $aadUser.id)
    
    switch -wildcard ($aadUser.userPrincipalName.ToLower()) {
        $null { 
            Write-Error "UPN cannot be null!"
        }
        'admin@mngenvmcap*' {
            Write-Host ("User: [{0}] is an admin and will be skipped." -f $aadUser.displayName)
        }
        'ms-serviceaccount@mngenvmcap*' {
            Write-Host ("User: [{0}] is an admin and will be skipped." -f $aadUser.displayName)
        }
        '*microsoft.com#ext#*'{
            Write-Host ("User: [{0}] is a Microsoft employee and will be skipped." -f $aadUser.displayName)
        }
        Default {
            Write-Warning ("Removing user: [{0}] with id [{1}] and UPN: [{2}]..." -f $aadUser.displayName, $aadUser.id, $aadUser.userPrincipalName)
            Invoke-RestMethod -Uri $($uri + '/' + $aadUser.id) -Headers @{'Authorization'='Bearer '+ $authToken.token} -Method Delete
            Write-Host ("Removed user: [{0}] with id [{1}]" -f $aadUser.displayName, $aadUser.id)
        }
    }
}