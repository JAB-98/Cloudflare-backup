$baceurl = "https://api.cloudflare.com/client/v4/"
$Authorization = $args[0]
#Set key here if you want to run as task
#$Authorization = "Bearer "
$Domains = $null
$Zone = $null
if ($null -eq $Authorization) {
    do {
        Write-Host "Please enter Cloudflare API Code (e.g. Bearer YTS): " -NoNewline
        $Authorization = Read-Host
        write-host "Is this correct '$($Authorization)' (Y/N): " -nonewline
    } while ((Read-Host).ToLower() -ne "y")
}
if ("zones" -notin (Get-ChildItem).name) {
    mkdir zones
}
do {
    $DomainsTemp = Invoke-webrequest -Uri "$($baceurl)zones" -Method Get -Headers @{"Authorization" = $Authorization } | ConvertFrom-Json
    if ($null -eq $Domains) {
        $Domains = $DomainsTemp.result
    }
    else {
        foreach ($currentItemName in $DomainsTemp.result) {
            $Domains += $currentItemName
        }
    }
    
} while ($DomainsTemp.result_info.page -lt $DomainsTemp.result_info.total_pages)
foreach ($currentItemName in $Domains) {
    do {
        $ZoneTeamp = Invoke-webrequest -Uri "$($baceurl)zones/$($currentItemName.id)/dns_records" -Method Get -Headers @{"Authorization" = $Authorization } | ConvertFrom-Json
        if ($null -eq $Zone) {
            $Zone = $ZoneTeamp.result
        }
        else {
            foreach ($_ in $ZoneTeamp.result) {
                $Zone += $_
            }
        }
        
    } while ($ZoneTeamp.result_info.page -lt $ZoneTeamp.result_info.total_pages)
    Write-Host "$($currentItemName.name) Has exported to zone file" -ForegroundColor Green
    $zone | Select-Object name, type, content | ConvertTo-Csv -Delimiter `t -UseQuotes Never -NoHeader | Set-Content -Path "zones\$($currentItemName.name).zone"
    $zone | ConvertTo-Json| Set-Content -Path "zones\$($currentItemName.name).json"
}