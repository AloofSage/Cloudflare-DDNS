# DDNS Cloudflare PowerShell Script

[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/AloofSage/Cloudflare-DDNS)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://mit-license.org/)

_Adapted from [fire1ce/DDNS-Cloudflare-PowerShell](https://github.com/fire1ce/DDNS-Cloudflare-PowerShell)_

- DDNS Cloudflare PowerShell script for **Windows**.
- Choose an IP source address from **wan**, **lan**, **tailscale** or **explicit**.
- Set other options like ttl and proxied
- Will create new records if they don't already exist

## Requirements

- Cloudflare [api-token](https://dash.cloudflare.com/profile/api-tokens) with ZONE-DNS-EDIT and ZONE-DNS-READ Permissions
- Tailscale CLI in your path (only needed if you want to use Tailscale)
- Enabled running unsigned PowerShell scripts

### Creating Cloudflare API Token and Zone ID

To create a CloudFlare API token for your DNS zone go to [https://dash.cloudflare.com/profile/api-tokens][cloudflare-api-token-url] and follow these steps:

1. Click Create Token
2. Select Create Custom Token
3. Provide the token a name, for example, `example.com-dns-zone-readonly`
4. Grant the token the following permissions:
   - Zone - DNS - Edit
   - Zone - DNS - Read
5. Set the zone resources to:
   - Include - Specific Zone - `example.com`
6. Complete the wizard and use the generated token in the `DEFAULT_api_zone_token` variable in `cloudflare-ddns_conf.ps1` file
7. Go to the dashboard/overview for your domain
8. In the right sidebar find Zone ID in the API section
9. Copy this ID and use it in the `DEFAULT_zone_id` variable in `cloudflare-ddns_conf.ps1` file

## Installation

[Download the Cloudflare-DDNS zip file](https://github.com/AloofSage/Cloudflare-DDNS/archive/refs/heads/master.zip) & Unzip.
Rename the folder and move to a place of your choosing.

## Config Parameters

Update the config parameters inside the *cloudflare-ddns_conf.ps1* by editing accordingly. See below for examples.

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

Configure domain records by adding new entries to the zone array.
You can copy examples from the commented out code at the bottom of the files.
E.g.:

    $domains += (@{
        name = "example.com";
        ip_source = [IpSource]::wan;
    })
    $domains += (@{
        name = "sub1.example.com";
        ip_source = [IpSource]::explicit;
        ip = "255.255.255.255";
        proxied = $False;
        ttl = 3000
    })
    $domains += (@{
        name = "sub2.example2.com";
        ip_source = [IpSource]::lan;
        zone_id = "override DEFAULT by putting different id here"
        zone_api_token = "override DEFAULT by putting different id here"
    })
    $domains += (@{
        name = "sub3.example.com";
        ip_source = [IpSource]::tailscale;
    })


## Running The Script

Open cmd/powershell

Example:

```bash
powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\Cloudflare-DDNS\cloudflare-ddns.ps1
```

## Automation With Windows Task Scheduler

Example:
Run at boot with 1 min delay and repeat every 10 min

- Open Task Scheduler
- Action -> Create Task
- **General Menu**
  - Name: update-cloudflare-dns
  - Run whether user is logged on or not
- **Trigger**
  - New...
  - Begin the task: At startup
  - Delay task for: 1 minute
  - Repeat task every: 10 minutes
  - for duration of: indefinitely
  - Enabled
- **Actions**
  - New...
  - Action: Start a Program
  - Program/script: _C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe_
  - Add arguments: _-ExecutionPolicy Bypass -File C:\Scripts\Cloudflare-DDNS\cloudflare-ddns.ps1_
  - ok
  - Enter your user's password when prompted
- **Conditions**
  - Power: Uncheck - [x] Start the task only if the computer is on AC power

## Logs

This Script will create a log file with **only** the last run information  
Log file will be located in same directory.

## Limitations

- Does not support IPv6

## License

### MIT License

Copyright© 3os.org @2020

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

<!-- urls -->
<!-- appendices -->

[cloudflare-api-token-url]: https://dash.cloudflare.com/profile/api-tokens 'Cloudflare API Token'

<!-- end appendices -->