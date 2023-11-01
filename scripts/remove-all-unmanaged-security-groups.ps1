Write-Host "Removing all unmanaged groups..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Host ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$api_resource = "groups"

$uri = "https://graph.microsoft.com/$graphApiVersion/$($api_resource)"
Write-Verbose $uri
$allAADGroups = Invoke-RestMethod -Uri $uri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method Get

$allGroups = $allAADGroups.value
Write-Host "Processing [$($allGroups.Count)] Groups..."

foreach ($aadGroup in $allGroups) {
    Write-Host ("Processing Group: [{0}] with id [{1}]..." -f $aadGroup.displayName, $aadGroup.id)
    
    
}