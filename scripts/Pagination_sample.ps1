$ApiUrl = 'https://graph.microsoft.com/v1.0/groups?$filter=groupTypes/any(c:c+eq+''Unified'')'



            $GraphDataGroups = @()

            do {

                $Results = Invoke-RestMethod -Headers $APIHeader -Uri $ApiUrl -Method Get



                if ($Results.value) {

                    $GraphDataGroups += $Results.value

                }

                else {

                    $GraphDataGroups += $Results

                }



                $ApiUrl = $Results.'@odata.nextlink'

            } until (!($ApiUrl))
Collapse

 

has context menu