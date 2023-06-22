Write-Host "Removing all hackathon participants..."


    $graphApiVersion = "beta"
    $User_resource = "users"
    $authToken = Get-AzAccessToken -ResourceUrl "https://graph.microsoft.com"

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
    Write-Verbose $uri
    $allUsers = Invoke-RestMethod -Uri $uri -Headers @{'Authorization'='Bearer '+ $authToken.token} -Method Get
    $allUsers.value | ForEach-Object{
        Write-Host ("User: [{0}] with id [{1}] and email address: [{2}]" -f $_.displayName, $_.id, $_.mail)

        try {
            Write-Host ("User Id is [{0}]" -f $_.id)

            if($_.id -eq "" -or $null -eq $_.id){
                Write-Warning "User Id is empty"
            }
            else 
            {
                if($_.mail -eq "" -or $null -eq $_.mail)
                {
                    Write-Host ("User email is empty, continue deletion [{0}]" -f $_.id)

                    Write-Host ("Removing user [{0}]" -f $_.mail)
                    # Write-Host ("Skip for now to prevent deletion [{0}]" -f $_.mail)

                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userId"
                    Write-Verbose $uri
                    Invoke-RestMethod -Uri $uri -Headers @{'Authorization'='Bearer '+ $authToken.token} -Method Delete
                }
                else
                {
                    if (($_.mail).StartsWith("admin@MngEnvMCAP") -or ($_.mail).EndsWith("@microsoft.com")){
                        Write-Host ("User: [{0}] with email address: [{1}] is an admin or Microsoft colleague and will be skipped." -f $_.displayName, $_.mail)
                    }
                    else
                    {
                        Write-Host ("Removing user [{0}]" -f $_.mail)
                        # Write-Host ("Skip for now to prevent deletion [{0}]" -f $_.mail)
    
                        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userId"
                        Write-Verbose $uri
                        Invoke-RestMethod -Uri $uri -Headers @{'Authorization'='Bearer '+ $authToken.token} -Method Delete
                    }

                }


                

                }
                
            
        }
        catch 
        {
            Write-Warning "Failed to remove users: $($_.Exception.Message)"
        }
    }    

    
