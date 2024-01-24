
function Get-RssAddressJSON {
    $feedPath = Join-Path -Path $env:USERPROFILE -ChildPath 'rssfeed' -AdditionalChildPath 'RssFeed.json'
    Write-Host $feedPath
    $list = $null
    if ((Test-Path -Path $feedPath)) {
        $list = Get-Content $feedPath | ConvertFrom-Json
    }
    return $list
}

<#
.SYNOPSIS
    Creates a JSON file with a single feed, including its name, URI, and interval.

.DESCRIPTION
    The New-RSSJson function creates a JSON file that stores RSS feed information. It takes parameters for the feed's name, URI, interval, and optional authentication token. If the JSON file already exists, the function appends the new feed to the existing list. If the file doesn't exist, it creates a new one.

.PARAMETER Name
    Specifies the name of the RSS feed.

.PARAMETER URI
    Specifies the URI of the RSS feed.

.PARAMETER Interval
    Specifies the interval (in seconds) for checking new episodes. The default value is 60 * 60 * 24 (24 hours).

.PARAMETER Auth
    Specifies an optional authentication token for the RSS feed.

.EXAMPLE
    New-RSSJson -Name "My Feed" -URI "https://example.com/rss" -Interval 3600 -Auth "myToken"

    This example creates a JSON file with a feed named "My Feed" that has a URI of "https://example.com/rss". It checks for new episodes every 3600 seconds (1 hour) and uses an authentication token "myToken".

#>
function New-RSSJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Name,
        [Parameter(Mandatory = $true)]
        [uri]
        $URI,
        [Parameter(Mandatory = $false)]
        [string]
        $Interval = '60 * 60 * 24',
        [Parameter(Mandatory = $false)]
        [string]
        $Auth
    )
    $feedPath = Join-Path -Path $env:USERPROFILE -ChildPath 'rssfeed' -AdditionalChildPath 'RssFeed.json'

    # Rest of the code...
}

function Set-RSSAuthToken {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Auth
    )
    $feedPath = Join-Path -Path $env:USERPROFILE -ChildPath 'rssfeed' -AdditionalChildPath 'RssFeed.json'
    if ((Test-Path -Path $feedPath)) {
        $data = (Get-Content $feedPath | ConvertFrom-Json)
        $data.auth = $Auth
        $data | ConvertTo-Json | Out-File $feedPath -Encoding utf8
        Write-Verbose -Message "Auth token updated."
    }
    else {
        Write-Error -Message "No rssfeed file found."
    }
}

function Set-JSONDescription {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Description
    )
    $feedPath = Join-Path -Path $env:USERPROFILE -ChildPath 'rssfeed' -AdditionalChildPath 'RssFeed.json'
    if ((Test-Path -Path $feedPath)) {
        $data = (Get-Content $feedPath | ConvertFrom-Json)
        $data.description = $Description
        $data | ConvertTo-Json | Out-File $feedPath -Encoding utf8
        Write-Verbose -Message "Description updated."
    }
    else {
        Write-Error -Message "No rssfeed file found."
    }

}

<#
.SYNOPSIS
Connects to the specified RSS feed URI and retrieves the RSS feed as an XML object.

.DESCRIPTION
The Connect-RssUri function connects to the specified RSS feed URI and retrieves the RSS feed as an XML object. It uses a WebClient object to download the RSS feed content and converts it to an XML object.

.PARAMETER RssUri
The URI of the RSS feed to connect to.

.EXAMPLE
Connect-RssUri -RssUri "https://example.com/rssfeed"

This example connects to the specified RSS feed URI and retrieves the RSS feed as an XML object.

.INPUTS
None

.OUTPUTS
System.Xml.XmlDocument

.NOTES

#>
function Connect-RssUri {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [uri]
        $RssUri
    )

    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "User-Agent: Mozilla/4.0 (compatible; MSIE 7.0;)")
    try {
        $wc.DownloadString($RssUri) | Out-Null
        $rssFeed = [xml]$wc.DownloadString($RssUri)
    }
    catch {

        # Try again after getting a cookie.
        $rssFeed = [xml]$wc.DownloadString($RssUri)
    }

    return $rssFeed
}

function Get-RssFeed {
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Show
    )
    $rssAddress = Get-RssAddressJSON
    if ([string]::IsNullOrEmpty($rssAddress) ) {
        Write-Error -Message "No Feeds were found."
    }

    # using Connect-rssuri, connect to the feed, download a xml file and save it to temp\rssfeed\<showname>.xml
    $uri = ($rssAddress.rss | Where-Object { $_.Name -iMatch $show }).uri
    Write-Host $uri

    $xmlContent = Connect-RssUri -RssUri $uri
    $xml = [xml]$xmlContent
    $rssName = $xml.rss.channel.title

    # save to temp folder
    if(!(Test-Path -Path ("$($env:TEMP)\rssfeed"))){
        New-Item -Path ("$($env:TEMP)\rssfeed") -Type Directory -Force | Out-Null
    }
    $xmlContent.Save("{0}\rssfeed\{1}\{1}.xml" -f $env:temp,$rssName)

}



<#
.SYNOPSIS
Retrieves the details of a show episode from an RSS feed.

.DESCRIPTION
The get-rssShowEpisodeDetails function retrieves the details of a show episode from an RSS feed. It takes an XML object representing the RSS feed as input and returns a custom object containing the episode details.

.PARAMETER RssFeed
The XML object representing the RSS feed.

.EXAMPLE
$xml = [xml](Get-Content "C:\path\to\feed.xml")
$episodeDetails = get-rssShowEpisodeDetails -RssFeed $xml
$episodeDetails.Name

This example demonstrates how to retrieve the episode details from an RSS feed and access the episode name.

#>
function get-rssShowEpisodeDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [xml]
        $RssFeed
    )
    $details = [PSCustomObject]@{
        Name = ($rssFeed.rss.channel).title
    }

    return $details
}

<#
.SYNOPSIS
    Retrieves episode details from an RSS feed.

.DESCRIPTION
    The Get-EpisodeDetails function retrieves episode details from an RSS feed. It takes an XML object representing the RSS feed as input and returns a collection of episode objects.

.PARAMETER RssFeed
    Specifies the XML object representing the RSS feed.

.OUTPUTS
    System.Collections.ArrayList
    Returns a collection of episode objects.

.EXAMPLE
    $rssFeed = [xml](Get-Content -Path "C:\path\to\rssfeed.xml")
    $episodes = Get-EpisodeDetails -RssFeed $rssFeed
    $episodes | ForEach-Object {
        Write-Host "Title: $($_.Title)"
        Write-Host "Episode: $($_.Episode)"
        Write-Host "SubTitle: $($_.SubTitle)"
        Write-Host "Date: $($_.Date)"
        Write-Host "URL: $($_.URL)"
        Write-Host "FileName: $($_.FileName)"
        Write-Host "Length: $($_.Length)"
        Write-Host "Type: $($_.Type)"
        Write-Host
    }
#>
function Get-EpisodeDetails {
    [CmdletBinding()]
    param (
        [Parameter()]
        [xml]
        $RssFeed
    )

    $episodeList = New-Object -TypeName System.Collections.ArrayList
    $items = $rssFeed.rss.channel.item
    $items | ForEach-Object {
        $item = $_
        $fullTitle = [System.String]$item.Title[1]

        $fileDetails = [uri]$item.enclosure.url
        $namePosition = ($fileDetails.Segments.Count - 1)

        $object = [PSCustomObject]@{
            Title    = $fullTitle
            Episode  = $item.episode
            SubTitle = $item.subTitle
            Date     = $item.pubDate
            URL      = $fileDetails.AbsoluteUri
            FileName = $fileDetails.Segments[$namePosition].ToString()
            Length   = [int64]$item.enclosure.length
            Type     = $item.enclosure.type.ToString()
        }
        $episodeList.Add($object) | Out-Null
    }

    return $episodeList
}

<#
.SYNOPSIS
    Retrieves and downloads podcast episodes based on the specified show name.

.DESCRIPTION
    The Get-Podcast function retrieves the RSS feed address, searches for the specified show name in the feed, and downloads the latest episode. If the episode is already cached, it will not be downloaded again.

.PARAMETER Show
    Specifies the name of the show to retrieve episodes for.

.EXAMPLE
    Get-Podcast -Show "My Favorite Podcast"
    Retrieves and downloads the latest episode of the "My Favorite Podcast" show.

.NOTES
    Author: [Your Name]
    Date: [Current Date]
#>
function Get-Podcast {
     [CmdletBinding()]
     param (
          [Parameter(Mandatory = $true)]
          [string]
          $Show
     )

     # Rest of the code...
}
function Get-Podcast {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $Show
    )

    Write-Host "Requested show: $show" -ForegroundColor Green
    $rssAddress = Get-RssAddress
    if ([string]::IsNullOrEmpty($rssAddress) ) {
        Write-Error -Message "No Feeds were found."

        #ToDo: add a way to add new rss feeds.
    }

    $uri = ($rssAddress.rss | Where-Object { $_.Name -iMatch $show }).uri
    Write-Host $uri

    $rssFeed = Connect-RssUri -RssUri $uri

    $episodes = Get-EpisodeDetails -RssFeed $rssFeed
    $item = $episodes | Select-Object -First 1
    if ($item) {
        $item

        $pdCstDir = Join-Path -Path $env:TEMP -ChildPath 'PodCast'
        if ( (Test-Path -Path $pdCstDir) ) {
            [System.IO.DirectoryInfo]$podcast = $pdCstDir
        }
        else {
            $podcast = New-Item -Path $pdCstDir -ItemType Directory
        }
        $outFilePath = Join-Path -Path $podcast.FullName -ChildPath $item.FileName

        $isNotCache = $true
        if (Test-Path -Path $outFilePath) {

            $localFile = Get-ChildItem -Path $outFilePath -File
            if ($item.length -ne $localFile.Length) {
                $isNotCache = $true
            }
            else {
                $isNotCache = $false
                Write-Host "Cached file already exists."
            }
        }

        if ($isNotCache) {
            Invoke-WebRequest -Uri $item.URL -OutFile $outFilePath
        }
        Write-Host "Video File: $outFilePath"
        & $outFilePath
    }
    else {
        Write-Host "No shows were found from the URI: $uri"
    }
}