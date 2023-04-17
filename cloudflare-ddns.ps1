[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#import logging function
. ./logging.ps1

$DATE = Get-Date -UFormat "%Y/%m/%d %H:%M:%S"

Write-Log "****************************************************************"
Try {
    . $PSScriptRoot\cloudflare-ddns_conf.ps1 
}
Catch {
    Write-Log "Error! Missing cloudflare-ddns_conf.ps1 or invalid syntax" -Severity error
    Exit
}
Write-Log "----$DATE----" 
Write-Log "Starting Cloudflare DNS record updates" 
Write-Log "api_base_url: $api_base_url" -Severity debug
Write-Log "cloudflare_headers: `n`t" -Severity debug
Write-Log $cloudflare_headers -Severity debug
Write-Log "wan_ip_lookup_url: $wan_ip_lookup_url" -Severity debug
Write-Log "****************************************************************"

$ip_wan         = $null
$ip_lan         = $null
$ip_tailscale   = $null

Function GetIp {
    param (
        [IpSource] $source
    )

    switch ($source){
        wan {
            if ($null -eq $ip_wan){
                $ip = (Invoke-RestMethod -Uri $wan_ip_lookup_url -TimeoutSec 10).Trim()
                if (!([bool]$ip)) {
                  Write-Log "Error! Can't get wan ip from $wan_ip_lookup" -Severity error
                  Exit
                }
                $script:ip_wan = $ip
            }
            Write-Log "WAN IP is: ${ip_wan}" -Severity debug
            $ip_wan
            break
        }
        lan {
            if ($null -eq $ip_lan){
                $ip = $((Find-NetRoute -RemoteIPAddress $lan_ip_lookup_url).IPAddress|out-string).Trim()
                if (!([bool]$ip) -or ($ip -eq "127.0.0.1")) {
                  Write-Log "Error! Can't get lan ip address from $lan_ip_lookup_url" -Severity error
                  Exit
                }
                $script:ip_lan = $ip
            }
            Write-Log "LAN IP is ${ip_lan}" -Severity debug 
            $ip_lan
            break
        }
        tailscale {
            if ($null -eq $ip_tailscale){
                $ip = (tailscale ip -4)
                if (!([bool]$ip)){
                    Write-Log "Error! Can't get tailscale ip address" -Severity error
                    Exit 
                }
                $script:ip_tailscale = $ip
            }
            Write-Log "Tailscale IP is ${ip_tailscale}" -Severity debug
            $ip_tailscale
            break
        }
    }
}

###--------------------------------
###--MAIN--
###--------------------------------
foreach ($domain in $domains) {
    Write-Log "-----------------------------------------------------------"
    Write-Log "Processing:`t $($domain.name)"
    Write-Log "IP Source:`t $($domain.ip_source)"
    if ([IpSource]$domain.ip_source -eq [IpSource]::explicit) {
        $new_ip = $domain.ip
    }
    else {
        $new_ip = GetIp -source $domain.ip_source
    }
    Write-Log "New IP: $new_ip"

    if ($domain.ContainsKey('zone_id')){
        $zone_id = $domain.zone_id
    }
    else {
        $zone_id = $DEFAULT_zone_id
    }
    if ($domain.ContainsKey('zone_api_token')){
        $zone_api_token = $domain.zone_api_token
    }
    else {
        $zone_api_token = $DEFAULT_zone_api_token
    }
 
    $base_url = $api_base_url -f $zone_id
    $headers = $cloudflare_headers.Clone()
    $headers.Authorization = $headers.Authorization -f $zone_api_token

    $list_records_request = @{
        Uri     = "$base_url/dns_records?name=$($domain.name)&type=A"
        Headers = $headers
    }
        
    $response = Invoke-RestMethod @list_records_request
    if($response.success -ne "True") {
        Write-Log "There was an error fetching record for $($domain.name)" -Severity error
        continue #foreach
    }

    $create_new = $False
    if($response.result_info.count -lt 1){
        Write-Log "No record found for $($domain.name). Will create new record."
        $create_new = $True
    }
    else {
        $record_id = $response.result[0].id
        Write-Log "Using first returned record id: $record_id"
    }

    $body = @{
        "type"    = "A"
        "name"    = $domain.name
        "content" = $new_ip
      }
    if ($create_new){
        $body += @{"proxied" = $True}
        $body += @{"ttl" = 1}
    }
    if ($domain.ContainsKey('ttl')){
        $body["ttl"] = $domain.ttl
    }
    if ($domain.ContainsKey('proxied')){
        $body["proxied"] = $domain.proxied
        #proxied records are set to ttl=1 by CloudFlare
        if ($body["proxied"] -eq $True) {$body["ttl"] = 1}
    }
    if ($domain.ip_source -eq [IpSource]::lan -Or $domain.ip_source -eq [IpSource]::tailscale){
        $body["proxied"] = $false
    }

    #test if update needed AFTER body created so can use $body instead of $domain
    $needs_update = $False
    if (!$create_new){
        if ($response.result[0].content -ne $new_ip) 
        {$needs_update = $True}
        if ($body.ContainsKey('ttl') -And ($response.result[0].ttl -ne $body['ttl']))
        {$needs_update = $True}
        if ($body.ContainsKey('proxied') -And ($response.result[0].proxied -ne $body['proxied']))
        {$needs_update = $True}
        if (!$needs_update){
            Write-Log "Skipping: all record info is the same."
            continue #foreach
        }   
    }

    $cloudflare_request_uri = "$base_url/dns_records"
    if (!$create_new){
        $cloudflare_request_uri += "/$record_id"
    }
    $cloudflare_request_method = If ($create_new) {'POST'} Else {'PATCH'}
    
    $cloudflare_request = @{
        Uri     = $cloudflare_request_uri
        Method  = $cloudflare_request_method
        Headers = $headers
        Body    = $body | ConvertTo-Json
    }
    
    $update_dns_record_response = Invoke-RestMethod @cloudflare_request
    $result = $update_dns_record_response.success
    Write-Log "Record update successful?: $result"
    

} #end foreach

