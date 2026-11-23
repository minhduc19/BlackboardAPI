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
$apiPrefix = '/learn/api/public/v2/'

function Get-CourseGradebookColumns {
    param ([string]$CourseReference)

    $pageUrl = [uri]"${origin}${apiPrefix}courses/$CourseReference/gradebook/columns"
    $seenPages = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)

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
            throw 'Blackboard returned a gradebook columns response without results.'
        }
        $response.results

        if ($response.paging.nextPage) {
            $pageUrl = [uri]::new($pageUrl, [string]$response.paging.nextPage)
        } else {
            $pageUrl = $null
        }
    }
}

function Add-GradebookCsvFields {
    param (
        [pscustomobject]$Value,
        [System.Collections.Specialized.OrderedDictionary]$Row,
        [string]$Prefix
    )

    foreach ($property in $Value.PSObject.Properties) {
        # Escape literal dots so a property name cannot collide with a nested path.
        $name = $property.Name.Replace('~', '~0').Replace('.', '~1')
        $path = "$Prefix$name"
        $field = $property.Value

        if ($field -is [pscustomobject] -and @($field.PSObject.Properties).Count -gt 0) {
            Add-GradebookCsvFields -Value $field -Row $Row -Prefix "$path."
        } elseif ($field -is [array] -or $field -is [pscustomobject]) {
            $Row[$path] = ConvertTo-Json -InputObject $field -Depth 100 -Compress
        } elseif ($field -is [datetime] -or $field -is [datetimeoffset]) {
            $Row[$path] = $field.ToString('o', [Globalization.CultureInfo]::InvariantCulture)
        } else {
            $Row[$path] = [Convert]::ToString($field, [Globalization.CultureInfo]::InvariantCulture)
        }
    }
}

function ConvertTo-GradebookCsvLine {
    param ([string[]]$Cells)

    ($Cells | ForEach-Object { '"' + ([string]$_).Replace('"', '""') + '"' }) -join ','
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

$csvHeaders = [System.Collections.Generic.List[string]]::new()
$csvHeaders.Add('course')
$seenHeaders = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
[void]$seenHeaders.Add('course')

$rows = foreach ($course in $courses) {
    $reference = 'courseId:' + [uri]::EscapeDataString($course)
    if ($course -match '^(courseId|externalId|uuid):(.+)$') {
        $idType = $Matches[1]
        if ($idType -ieq 'courseId') {
            $idType = 'courseId'
        } elseif ($idType -ieq 'externalId') {
            $idType = 'externalId'
        } else {
            $idType = 'uuid'
        }
        $reference = "${idType}:" + [uri]::EscapeDataString($Matches[2])
    } elseif ($course -cmatch '^_[0-9]+_[0-9]+$') {
        $reference = $course
    }

    try {
        $columns = @(Get-CourseGradebookColumns -CourseReference $reference)
        if ($columns.Count -eq 0) {
            @{ course = $course }
        }
        foreach ($column in $columns) {
            $row = [System.Collections.Specialized.OrderedDictionary]::new([StringComparer]::Ordinal)
            $row.Add('course', $course)
            Add-GradebookCsvFields -Value $column -Row $row -Prefix 'column.'
            foreach ($name in $row.Keys) {
                if ($seenHeaders.Add($name)) {
                    $csvHeaders.Add($name)
                }
            }
            $row
        }
    } catch {
        throw "Could not export course '${course}': $_"
    }
}

& {
    ConvertTo-GradebookCsvLine -Cells ($csvHeaders.ToArray())
    foreach ($row in $rows) {
        $cells = foreach ($name in $csvHeaders) {
            [string]$row[$name]
        }
        ConvertTo-GradebookCsvLine -Cells $cells
    }
} | Set-Content -LiteralPath $outputFile -Encoding UTF8
