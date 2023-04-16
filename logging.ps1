<#
    dot source include this file in the script that will be using it
#>
enum LogDestination {
    file = 1
    host = 2
    csv = 4
}

enum LogLevel {
    debug = 10
    info = 20
    warn = 30
    error = 40
}

$_LOG_LEVEL = [LogLevel]::info
$_LOG_DESTINATION = [LogDestination]::file
#$_LOG_DESTINATION = [LogDestination]::file + [LogDestination]::host

#TO-DO get this to refer to the script that included this one
$_LOG_NAME = (Get-Item $MyInvocation.MyCommand.Name).BaseName + ".log"
$_LOG_FULL_PATH = "$PSScriptRoot/$_LOG_NAME"

New-Item $_LOG_FULL_PATH -ErrorAction SilentlyContinue
Clear-Content $_LOG_FULL_PATH

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Position=0,ValuefromPipeline=$True)]
        $Message,
 
        [Parameter()]
        [LogLevel]$Severity = [LogLevel]::info,

        [Parameter()]
        [LogDestination]$Destination = $_LOG_DESTINATION
    )
    
    if ([int]$Severity -ge [int]$_LOG_LEVEL){
        if (([int]$Destination -band [int][LogDestination]::host) -eq [int][LogDestination]::host){
            Write-Output $Message | Write-Host
        }
        if (([int]$Destination -band [int][LogDestination]::file) -eq [int][LogDestination]::file){
            Write-Output $Message | Out-File -FilePath $_LOG_FULL_PATH -Append
        }
        if (([int]$Destination -band [int][LogDestination]::csv) -eq [int][LogDestination]::csv){
            #not implemented
        }
    }
    
}

