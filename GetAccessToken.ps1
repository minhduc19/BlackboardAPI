function GetAccessToken {
    param (
        [string]$credentialsPath = ".\credentials.json",
        [string]$baseUrl = "https://bb.reading.ac.uk"
    )

    # Read credentials from JSON
    if (!(Test-Path $credentialsPath)) {
        throw "Credentials file not found: $credentialsPath"
    }

    $creds = Get-Content $credentialsPath | ConvertFrom-Json
    $clientId = $creds.client_id
    $clientSecret = $creds.client_secret

    $authHeader = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${clientId}:${clientSecret}"))

    $headers = @{
        "Authorization" = "Basic $authHeader"
        "Content-Type"  = "application/x-www-form-urlencoded"
    }

    $body = "grant_type=client_credentials"

    $response = Invoke-RestMethod -Uri "${baseUrl}/learn/api/public/v1/oauth2/token" `
                                  -Method POST -MaximumRedirection 0 -ErrorAction Stop `
                                  -Headers $headers `
                                  -Body $body

    return $response.access_token
}
