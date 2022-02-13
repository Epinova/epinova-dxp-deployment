
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$warmupThisUrl = "https://epinova.se/"

function Invoke-WarmupRequest {
    <#
    .SYNOPSIS
        Make a request against a URL to warm it up.

    .DESCRIPTION
        Make a request against a URL to warm it up.

    .PARAMETER RequestUrl
        The URL that should be warmed-up.

    .EXAMPLE
        Invoke-WarmupRequest -RequestUrl "https://epinova.se/news-and-stuff"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $RequestUrl
    )
    $ProgressPreference = 'SilentlyContinue'
    try {
        Invoke-WebRequest -Uri $RequestUrl -UseBasicParsing -MaximumRedirection 1 | Out-Null #-Verbose:$false
        
    } catch {
        #$_.Exception.Response
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Could not request $RequestUrl. Something went wrong. $statusCode"
    }
    $ProgressPreference = 'Continue'
}

function Invoke-WarmupSite{
    <#
    .SYNOPSIS
        Warm a site.

    .DESCRIPTION
        Will make a request to the specified URL. Take all links it can find and make a request for each link to warm up the site.

    .PARAMETER Url
        The URL that should be warmed-up.

    .EXAMPLE
        Invoke-WarmupSite -Url "https://epinova.se"

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String] $Url
    )

    try {
        if ($Url.EndsWith("/")) {
            $Url = $Url.Substring(0, $Url.Length - 1)
        }
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -Verbose:$false -MaximumRedirection 1
    
        if ($null -ne $response){ 
            foreach ($link in $response.Links){
                if ($null -ne $link -and $null -ne $link.href) {
                    if ($link.href.StartsWith("/") -and $false -eq $link.href.StartsWith("//")){
                        $newUrl = $Url + $link.href
                        Write-Host $newUrl
                        Invoke-WarmupRequest -requestUrl $newUrl
                    } elseif ($link.href.StartsWith($Url)) {
                        Write-Host $link.href
                        Invoke-WarmupRequest -requestUrl $link.href
                    } #else { #Used for debuging
                    #    Write-Warning "Not: $($link.href)" 
                    #}
                }
            }
            Write-Host "Warm up site $Url - done."
        } else {
            Write-Warning "Could not request $Url. response = null"
        }
    } catch {
        Write-Warning "Could not warmup $Url"
    }
}

Invoke-WarmupSite $warmupThisUrl
# ------------------------------------------------



# $sleepTime = 2
# $timeout = 40
# $hide200Requests = $false

# $defaultHeader = @{"User-Agent"="SpaceSpider"}
# $urlList = @(
#     ("http://mobelstudion.se", @{"accept-language"="sv"}),
#     ("https://prod.indutradeportal.com/", $defaultHeader),
#     ("https://prod.indutradeportal.com/people/", $defaultHeader),
#     ("https://prod.indutradeportal.com/people/opportunities/", $defaultHeader)
# )

# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# function Mill {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [object] $urlList,
#         [Parameter(Mandatory = $true)]
#         [int] $sleepTime,
#         [Parameter(Mandatory = $true)]
#         [int] $timeout,
#         [Parameter(Mandatory = $true)]
#         [bool] $hide200Requests
#     )
#     $sw = [Diagnostics.Stopwatch]::StartNew()
#     $sw.Start()
#     $iterator = 0
#     while ($sw.Elapsed.TotalSeconds -lt $timeout) {
#         foreach ($urlObj in $urlList) {
#             CheckUrls -urlObj $urlObj -hide200Requests $hide200Requests
#         }
#         if ($iterator % 3 -eq 0) {
#             Write-Host "ElapsedSeconds: $($sw.Elapsed.TotalSeconds)"
#         }
#         Start-Sleep $sleepTime
#         if ($sw.Elapsed.TotalSeconds -ge $timeout) { break }
#         $iterator++
#     }
#     $sw.Stop()
# }
 
# function CheckUrls {
#     [CmdletBinding()]
#     param(
#         [Parameter(Mandatory = $true)]
#         [object] $urlObj,
#         [Parameter(Mandatory = $true)]
#         [bool] $hide200Requests
#     )
#     $swUrl = [Diagnostics.Stopwatch]::StartNew()
#     $swUrl.Start()
#     try {
#         $headers = $urlObj[1]
#         $url = $urlObj[0]
#           if ([string]::IsNullOrEmpty($headers)) {
#               $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Verbose:$false -MaximumRedirection 1
#           } else {
#               $response = Invoke-WebRequest -Uri $url -Headers $headers -UseBasicParsing -Verbose:$false -MaximumRedirection 1
#           }
#           $swUrl.Stop()
#           $statusCode = $response.StatusCode
#           $seconds = $swUrl.Elapsed.TotalSeconds
#           if ($statusCode -eq 200) {
#             if ($hide200Requests -ne $true){
#                 $statusDescription = $response.StatusDescription
#                 Write-Host "$url => Status: $statusCode $statusDescription in $seconds seconds" -ForegroundColor Black -BackgroundColor Green
#               }
#           } else {
#               Write-Warning "$url => Error $statusCode after $seconds seconds"
#           }
#       }
#       catch {
#           $swUrl.Stop()
#           $statusCode = $_.Exception.Response.StatusCode.value__
#           $errorMessage = $_.Exception.Message
#           $seconds = $swUrl.Elapsed.TotalSeconds
#           if ($statusCode -eq 500) {
#             Write-Host "$url => Error $statusCode after $seconds seconds: $errorMessage" -BackgroundColor Red
#           }
#           else {
#             Write-Host "$url => Error $statusCode after $seconds seconds: $errorMessage" -ForegroundColor Black -BackgroundColor Yellow
#           }
#       }
# }

# Mill -urlList $urlList -sleepTime $sleepTime -timeout $timeout -hide200Requests $hide200Requests
# Write-Output "---THE END---"