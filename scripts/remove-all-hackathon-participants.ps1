Write-Host "Removing all hackathon participants..."
$authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"
Write-Host ('Access Token acquired! Length: [{0}] chars - Expires on: [{1}]' -f $authToken.Token.Length, $authToken.ExpiresOn)
