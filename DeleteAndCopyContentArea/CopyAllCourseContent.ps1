function CopyAllCourseContent {
    param (
        [string]$accessToken,
        [string]$sourceCourseId,
        [string]$targetCourseId
    )

    # Define headers
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Bearer $accessToken")

    # Define JSON body
    $body = @"
{
  "targetCourse": {
    "id": "courseId:$targetCourseId"
  },
  "copy": {
    "announcements": false,
    "assessments": false,
    "blogs": false,
    "calendar": false,
    "contacts": false,
    "contentAlignments": false,
    "contentAreas": true,
    "discussions": "None",
    "glossary": false,
    "gradebook": false,
    "groupSettings": false,
    "journals": false,
    "retentionRules": false,
    "rubrics": false,
    "settings": {
      "availability": false,
      "bannerImage": false,
      "duration": false,
      "enrollmentOptions": false,
      "guestAccess": true,
      "languagePack": true,
      "navigationSettings": true,
      "observerAccess": false
    },
    "tasks": false,
    "wikis": false
  }
}
"@

    # Make the request
    $url = "https://bb.reading.ac.uk/learn/api/public/v2/courses/courseId:$sourceCourseId/copy"
    $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body

    return $response
}
