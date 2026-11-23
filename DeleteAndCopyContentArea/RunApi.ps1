param (
    [Parameter(Mandatory=$true)]
    [string]$templateCourseId,

    [Parameter(Mandatory=$true)]
    [string]$targetCourseId
)

# Dot source all function scripts
. ..\GetAccessToken.ps1
. .\GetCourseContentId.ps1
. .\DeleteCourseContent.ps1
. .\CopyAllCourseContent.ps1

# Step 1: Get Collaborate access token
$token = GetAccessToken
Write-Host "$token"

# Provide the Blackboard course ID
#$templateCourseId = "TEMPLATE_ULTRA_PY_CWI"
#$targetCourseId = "PYMWES-25-6_S12"
$contentIds = GetCourseContentIds -accessToken $token -courseId $targetCourseId

#Delete each content item
foreach ($id in $contentIds) {
    Write-Host "Attempting to delete content ID: $id"
    DeleteCourseContent -accessToken $token -courseId $targetCourseId -contentId $id
}

# Copy content
$response = CopyAllCourseContent -accessToken $token -sourceCourseId $templateCourseId -targetCourseId $targetCourseId
$response | ConvertTo-Json -Depth 10

