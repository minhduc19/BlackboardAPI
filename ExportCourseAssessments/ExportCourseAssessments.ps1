[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$CoursesPath,

    [Parameter(Mandatory)]
    [string]$OutputPath,

    [string]$CredentialsPath = (Join-Path $PSScriptRoot 'credentials.json'),

    [uri]$BaseUrl = 'https://bb.reading.ac.uk'
)

$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'GetAccessToken.ps1')

if (!$BaseUrl.IsAbsoluteUri -or $BaseUrl.Scheme -ne 'https' -or
    $BaseUrl.AbsolutePath -ne '/' -or $BaseUrl.UserInfo -or $BaseUrl.Query -or $BaseUrl.Fragment) {
    throw 'BaseUrl must be an HTTPS origin, such as https://bb.reading.ac.uk.'
}

$origin = $BaseUrl.GetLeftPart([UriPartial]::Authority)
$apiPrefix = '/learn/api/public/v1/'
$assessmentTypes = @(
    'resource/x-bb-assessment'
    'resource/x-bb-assignment'
    'resource/x-bb-asmt-assignment'
    'resource/x-bb-asmt-survey'
    'resource/x-bb-asmt-test'
)

function Get-CourseAssessments {
    param ([string]$CourseReference)

    $contentsUrl = "${origin}${apiPrefix}courses/$CourseReference/contents"
    $pending = [System.Collections.Generic.Queue[uri]]::new()
    $pending.Enqueue([uri]$contentsUrl)
    $seenItems = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $seenPages = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)

    while ($pending.Count -gt 0) {
        $pageUrl = $pending.Dequeue()
        while ($pageUrl) {
            if ($pageUrl.GetLeftPart([UriPartial]::Authority) -ne $origin -or $pageUrl.UserInfo -or
                !$pageUrl.AbsolutePath.StartsWith($apiPrefix, [StringComparison]::Ordinal)) {
                throw 'Blackboard returned a pagination URL outside the configured API.'
            }
            if (!$seenPages.Add($pageUrl.AbsoluteUri)) {
                throw 'Blackboard returned a repeated pagination URL.'
            }

            $response = Invoke-RestMethod -Uri $pageUrl -Method Get -Headers $headers -MaximumRedirection 0
            if ($null -eq $response.results) {
                throw 'Blackboard returned a course contents response without results.'
            }
            foreach ($item in $response.results) {
                if (!$item.id) {
                    throw 'Blackboard returned a course content item without an ID.'
                }
                if (!$seenItems.Add($item.id)) {
                    continue
                }
                if ($item.contentHandler.id -in $assessmentTypes) {
                    $item
                }
                if ($item.hasChildren) {
                    $childId = [uri]::EscapeDataString($item.id)
                    $pending.Enqueue([uri]"$contentsUrl/$childId/children")
                }
            }

            if ($response.paging.nextPage) {
                $pageUrl = [uri]::new($pageUrl, [string]$response.paging.nextPage)
            } else {
                $pageUrl = $null
            }
        }
    }
}

$inputFile = Get-Item -LiteralPath $CoursesPath
$outputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$pathComparison = [StringComparison]::Ordinal
if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    $pathComparison = [StringComparison]::OrdinalIgnoreCase
}
if ([string]::Equals($inputFile.FullName, $outputFile, $pathComparison)) {
    throw 'CoursesPath and OutputPath must refer to different files.'
}

$courses = @(Get-Content -LiteralPath $inputFile.FullName -Encoding UTF8 |
    ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
if ($courses.Count -eq 0) {
    throw 'The course list is empty.'
}

$token = GetAccessToken -credentialsPath $CredentialsPath -baseUrl $origin
if (!$token) {
    throw 'Blackboard did not return an access token.'
}
$headers = @{ Authorization = "Bearer $token"; Accept = 'application/json' }

$report = foreach ($course in $courses) {
    $reference = 'courseId:' + [uri]::EscapeDataString($course)
    if ($course -match '^(courseId|externalId):(.+)$') {
        $idType = $Matches[1]
        if ($idType -ieq 'courseId') {
            $idType = 'courseId'
        } else {
            $idType = 'externalId'
        }
        $reference = "${idType}:" + [uri]::EscapeDataString($Matches[2])
    } elseif ($course -cmatch '^_[0-9]+_[0-9]+$') {
        $reference = $course
    }

    try {
        [pscustomobject]@{
            course = $course
            assessments = @(Get-CourseAssessments -CourseReference $reference)
        }
    } catch {
        throw "Could not export course '${course}': $_"
    }
}

ConvertTo-Json -InputObject @($report) -Depth 100 |
    Set-Content -LiteralPath $outputFile -Encoding UTF8
