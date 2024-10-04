#Bace uri for cloudflare api
$baceurl = "https://api.cloudflare.com/client/v4/"
#Get auth tocken from args passed in from running script
$Authorization = $args[0]
#Set key here if you want to run as task
#$Authorization = "Bearer "

#clear vars for sript
$Domains = $null
$Zone = $null
#see if auth tocken set
if ($null -eq $Authorization) {
#wait for user to make sure the auth tocken is corrct
    do {
        Write-Host "Please enter Cloudflare API Code (e.g. Bearer YTS): " -NoNewline
        #get tocken from input
        $Authorization = Read-Host
        write-host "Is this correct '$($Authorization)' (Y/N): " -nonewline
        #check to make sure the user entered correct value
    } while ((Read-Host).ToLower() -ne "y")
}
if ("zones" -notin (Get-ChildItem).name) {
#make folder for files
    mkdir zones | $out-null
}
#counter
    $i=1
    #start getting all domains in account
do {
#api call to cloudflare
    $DomainsTemp = Invoke-webrequest -Uri "$($baceurl)zones?page=$($i)" -Method Get -Headers @{"Authorization" = $Authorization } | ConvertFrom-Json
    #if first page set the results to list
    if ($null -eq $Domains) {
        $Domains = $DomainsTemp.result
    }
    else {
    #go through each result and add to esiting list of domains
        foreach ($currentItemName in $DomainsTemp.result) {
            $Domains += $currentItemName
        }
    }
    #incress counter
    $i++
    #see if all api calls are completed
} while ($DomainsTemp.result_info.page -lt $DomainsTemp.result_info.total_pages)
foreach ($currentItemName in $Domains) {
    $zone = $null
    $i=1
    do {
        $ZoneTeamp = Invoke-webrequest -Uri "$($baceurl)zones/$($currentItemName.id)/dns_records?page=$($i)" -Method Get -Headers @{"Authorization" = $Authorization } | ConvertFrom-Json
        if ($null -eq $Zone) {
            $Zone = $ZoneTeamp.result
        }
        else {
            foreach ($_ in $ZoneTeamp.result) {
                $Zone += $_
            }
        }
        $i++
    } while ($ZoneTeamp.result_info.page -lt $ZoneTeamp.result_info.total_pages)
    Write-Host "$($currentItemName.name) Has exported to zone file" -ForegroundColor Green
    $zone | Select-Object name, type, content | ConvertTo-Csv -Delimiter `t -UseQuotes Never -NoHeader | Set-Content -Path "zones\$($currentItemName.name).zone"
    $zone | ConvertTo-Json| Set-Content -Path "zones\$($currentItemName.name).json"
}
