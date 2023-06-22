Write-Host "Removing all hackathon participants..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Host ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)

$graphApiVersion = "beta"
$User_resource = "users"

$uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
Write-Verbose $uri
$allUsers = Invoke-RestMethod -Uri $uri -Headers @{'Authorization' = 'Bearer ' + $authToken.token } -Method Get
$allUsers.value | ForEach-Object {
    Write-Host ("User: [{0}] with id [{1}] and email address: [{2}]" -f $_.displayName, $_.id, $_.mail)
}