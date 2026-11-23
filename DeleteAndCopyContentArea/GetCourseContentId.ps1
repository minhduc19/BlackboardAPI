function GetCourseContentIds {
    param (
        [string]$accessToken,
        [string]$courseId
    )

    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }

    $uri = "https://www.bb.reading.ac.uk/learn/api/public/v1/courses/courseId:$courseId/contents"

    $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $headers

    return $response.results | Select-Object -ExpandProperty id
}