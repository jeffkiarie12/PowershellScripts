function Get-EntraBitLockerKeys{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Device name to retrieve the BitLocker keys from Microsoft Entra ID")]
        [string]$DeviceName
    )
    $dev = Get-MGDevice -filter "displayName eq '$DeviceName'"
    $DeviceID = (Get-MGDevice -filter "displayName eq '$DeviceName'").DeviceId
    if ($DeviceID){
      $devOwner = (Get-MgDeviceRegisteredOwner -DeviceId $($dev.Id)).additionalproperties.displayName
      $KeyIds = (Get-MgInformationProtectionBitlockerRecoveryKey -Filter "deviceId eq '$DeviceId'").Id
      if ($keyIds) {
        $devKeyString = ""
        Write-Host -ForegroundColor Yellow "Device name: $devicename"
        Write-Host -ForegroundColor Yellow "Registered Owner: $devOwner"
        $devKeyString += "$devicename, $devOwner, "
        foreach ($keyId in $keyIds) {
          $recoveryKey = (Get-MgInformationProtectionBitlockerRecoveryKey -BitlockerRecoveryKeyId $keyId -Select "key").key
          Write-Host -ForegroundColor White " Key id: $keyid"
          Write-Host -ForegroundColor Cyan " BitLocker recovery key: $recoveryKey"
          $devKeyString += "$recoveryKey, "
        }
        $devKeyString | Out-File -FilePath ".\BitlockerKeys-$((Get-Date).ToString("MM-dd-yyyy")).csv" -Append
        } else {
        Write-Host -ForegroundColor Red "No BitLocker recovery keys found for device $DeviceName"
      }
    } else {
        Write-Host -ForegroundColor Red "Device $DeviceName not found"
    }
}

if (!(Get-Module -ListAvailable -Name Microsoft.Graph.Identity.SignIns)) {
    Install-Module Microsoft.Graph.Identity.SignIns
}
Import-Module Microsoft.Graph.Identity.SignIns

# Connect to Microsoft Graph, requesting the necessary permissions
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

$headers = "DeviceName, Registered Owner, Bitlocker Key"
$headers | Out-File -FilePath ".\BitlockerKeys-$((Get-Date).ToString("MM-dd-yyyy")).csv"
$winDevices = get-MgDevice -Filter "OperatingSystem eq 'Windows'" -All -ConsistencyLevel eventual
foreach($device in $winDevices){
    Get-EntraBitLockerKeys -DeviceName $device.DisplayName
    #Write-Host $device.OperatingSystem
}
