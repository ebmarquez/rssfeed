
function Get-RssAddress {
    $feedPath = Join-Path -Path $env:USERPROFILE -ChildPath 'rssfeed' -AdditionalChildPath 'RssFeed.json'
    Write-Host $feedPath
    $list = $null
    if ((Test-Path -Path $feedPath)) {
        $list = Get-Content $feedPath | ConvertFrom-Json
    }
    return $list
}

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