$api_base_url = "https://api.cloudflare.com/client/v4/zones/{0}"
$cloudflare_headers = @{"Authorization" = "Bearer {0}"; "Content-Type" = "application/json" }
$wan_ip_lookup_url = "https://checkip.amazonaws.com"
$lan_ip_lookup_url = "1.1.1.1"

$domains = @()

<#
    wan: looks up external ip with external website
    lan: uses powershell's find-netroute to find lan interface ip
    tailscale: uses tailscale CLI which must be in your path
    explicit: uses value supplied in the config 
#>
enum IpSource {
    wan
    lan
    tailscale
    explicit
}

###-----------------------------------------------
###----default values
###-----------------------------------------------
## Cloudflare's Zone ID
$DEFAULT_zone_id = "CLOUD FLARE ZONE ID HERE"
## Cloudflare Zone API Token
$DEFAULT_zone_api_token = "AN EDIT AND READ TOKEN HERE"

###-----------------------------------------------
###----add the records to update below
###-----------------------------------------------
###----required hashtable entries:
###--------name (always) - string
###--------ip_source (always) - IpSource enum
###--------ip (if ip_source==IpSource::explicit) - string
###----used if present (otherwise not changed):
###--------proxied - boolean
###--------ttl - integer (1 is AUTO or 120-7200 otherwise)
###--------zone_id & zone_api_token override DEFAULT if present - string 
###-----------------------------------------------
$domains += (@{
    name = "example.com";
    ip_source = [IpSource]::wan;
})
$domains += (@{
    name = "sub1.example.com";
    ip_source = [IpSource]::lan;
})
$domains += (@{
    name = "sub2.example.com";
    ip_source = [IpSource]::tailscale;
})
$domains += (@{
    name = "sub3.example.com";
    ip_source = [IpSource]::explicit;
    ip = "255.255.255.255"
})



<#COPY THIS FOR SIMPLE WAN UPDATE
$domains += (@{
    name = "sub1.example.com";
    ip_source = [IpSource]::wan;
})
#>

<#COPY THIS FOR MORE OPTIONS. OK TO REMOVE UNNEEDED FIELDS
$domains += (@{
    name = "sub2.example.com";
    ip_source = [IpSource]::lan;
    ip = "";
    proxied = $True;
    ttl = 1;
    zone_id = ""
    zone_api_token = ""
})
#>

