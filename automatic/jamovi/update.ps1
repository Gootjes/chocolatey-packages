import-module au
import-module Wormies-AU-Helpers

$releases = 'https://www.jamovi.org/download.html'

function global:au_SearchReplace {
  @{
    "$($Latest.PackageName).nuspec" = @{
      "(\<dependency .+?`"$($Latest.PackageName).install`" version=)`"([^`"]+)`"" = "`$1`"[$($Latest.Version)]`""
    }
  }
}

function GetStreams {
    $streams = [ordered]@{ }

    $root          = (Split-Path $releases -Parent).Replace(":\\", "://")
    $download_page = Invoke-WebRequest $releases -UseBasicParsing
    $urls         = $download_page.Links | ? href -match '.exe$' | % href

    $url_stable_i = $urls | select -First 1
    $url_stable_p = $url_stable_i -replace '.exe', '.zip'
    $version_stable = $url_stable_i -split '-|.exe' | select -Last 1 -Skip 2

    if (!$url_stable_i -or !$url_stable_p) {
        throw "Either portable or installer for stable stream (v'$version_stable') was not found. Please check for changes."
    }

    $url_current_i = $urls | select -Last 1
    $url_current_p = $url_current_i -replace '.exe', '.zip'
    $version_current = $url_current_i -split '-|.exe' | select -Last 1 -Skip 2

    if (!$url_current_i -or !$url_current_p) {
        throw "Either portable or installer for current stream (v'$version_current') was not found. Please check for changes."
    }

    $version_current = Get-FixVersion ($version_current)
    $version_current = $version_current  + '-current'

    $streams.Add('stable', @{
        Version = Get-FixVersion $version_stable;
        URL64_i = $root + $url_stable_i;
        URL64_p = $root + $url_stable_p;
        })

    $streams.Add('current', @{
        Version = $version_current;
        URL64_i = $root + $url_current_i;
        URL64_p = $root + $url_current_p;
        })

    Write-Host $streams.Count "streams collected:" $streams.Keys
    $streams
}

function global:au_GetLatest {

    return @{
        Streams = GetStreams
    }
}

if ($MyInvocation.InvocationName -ne '.') {
  update -ChecksumFor none
}
