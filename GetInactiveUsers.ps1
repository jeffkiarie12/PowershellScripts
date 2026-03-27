# Fill in empty values
$tenantId = ""
$clientId = ""
$clientSecret = ""
$scope = "https://graph.microsoft.com/.default"

# Get Graph API Access token
$tokenBody = @{
    grant_type    = "client_credentials"
    scope         = $scope
    client_id     = $clientId
    client_secret = $clientSecret
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $tokenBody
$accessToken = $tokenResponse.access_token
$secureAccessToken = ConvertTo-SecureString $accessToken -AsPlainText -Force
Connect-MgGraph -AccessToken $secureAccessToken

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $accessToken)
$headers.Add("Content-Type", "application/json")
# Change date to fit your inactivity criteria
$uri = 'https://graph.microsoft.com/v1.0/users?$filter=signInActivity/lastSignInDateTime le 2025-06-03T00:00:00Z&$select=id,displayName,userPrincipalName,signInActivity'

$Method = "GET"
$response = Invoke-RestMethod $uri -Method $Method -Headers $headers

$response.value | ForEach-Object {Write-Host $_.id $_.displayName $_.userPrincipalName $_.signInActivity.lastSignInDateTime}

#Format-Table -Property displayName, userPrincipalName, signInActivity[lastSignInDateTime] -AutoSize
