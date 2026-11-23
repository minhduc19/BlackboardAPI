function DeleteCourseContent {
    param (
        [string]$accessToken,
        [string]$courseId,
        [string]$contentId
    )

    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }

    $uri = "https://www.bb.reading.ac.uk/learn/api/public/v1/courses/courseId:$courseId/contents/$contentId"

    try {
        Invoke-RestMethod -Uri $uri -Method DELETE -Headers $headers
        Write-Host "Content item {$contentId} deleted successfully."
    }
    catch {
        Write-Error "Failed to delete content item {$contentId}: $_"
    }
}
