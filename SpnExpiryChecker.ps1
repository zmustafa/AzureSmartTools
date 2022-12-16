
# Replace with your Workspace Id
# Find in: Azure Portal > Log Analytics > {Your workspace} > Settings > Agents Management> WORKSPACE ID
$CustomerId = "xxxxxxxxxxxxxxxxxxxxxxx"  

# Replace with your Primary Key
# Find in: Azure Portal > Log Analytics > {Your workspace} > Settings > Agents Management > PRIMARY KEY
$SharedKey = "xxxxxxxxxxxxxxxxxxxxxxx"

# Specify the name of the record type that you'll be creating
# After logs are sent to the workspace, you will use "MyStorageLogs1_CL" as stream to query.
$LogType = "SPN_Logs_CL"

Function BuildSignature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId, $encodedHash
    return $authorization
}

# Create the function to create and post the request
Function PostLogAnalyticsData($customerId, $sharedKey, $body, $logType) {
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $rfc1123date
    $signature = BuildSignature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
    $TimeStampField = "TimeGenerated" # Important
    $headers = @{
        "Authorization"        = $signature;
        "Log-Type"             = $logType;
        "x-ms-date"            = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

    $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
    $response
    return $response.StatusCode
}

# Define AppId, secret and scope, your tenant name and endpoint URL
$AppId = 'xxxxxx' # azure app registration app
$AppSecret = 'xxxxxxxx'
$TenantName = "xxxxxxxxx"
$Url = "https://login.microsoftonline.com/$TenantName/oauth2/token?api-version=2020-06-01"

# Add System.Web for urlencode
Add-Type -AssemblyName System.Web

# Create body
$Body = @{
    client_id     = $AppId
    client_secret = $AppSecret
    resource      = 'https://graph.microsoft.com/'
    grant_type    = 'client_credentials'
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method      = 'POST'
    Body        = $Body
    Uri         = $Url
}

# Request the token!
$Request = Invoke-RestMethod @PostSplat

# Create header
$Header = @{
    Authorization = "$($Request.token_type) $($Request.access_token)"
    host          = 'graph.microsoft.com'
}

$Uri = "https://graph.microsoft.com/v1.0/applications" 
$count = 0
$apps = @()
do {
    $Results = Invoke-RestMethod -Uri $Uri -Headers $Header -Method "GET" -ContentType "application/json"
    $apps += $Results.value
    $count = $count + $Results.value.Count
    $count
    try { $Uri = $Results.'@odata.nextLink' } catch {}
} while ($null -ne $Uri);

Write-Host "App Count" $apps.Count

# Variables
$expiresInDays = 30
$today = (Get-Date).ToUniversalTime()
$futureDate = $today.AddDays($ExpiresInDays)

$Logs = @()
foreach ($app in $apps) {
    $AppName = $app.DisplayName
    $AppID = $app.objectid
    $ApplID = $app.AppId
    $secrets = $app.PasswordCredentials
    $certs = $app.KeyCredentials

    foreach ($s in $secrets) {
        $StartDate = [Datetime]::Parse($s.startDateTime)
        $EndDate = [Datetime]::Parse($s.endDateTime)
        $status = "ACTIVE"

        if ($EndDate -le $today) {
            $status = "EXPIRED"
        }      
        elseif ($EndDate -le $futureDate) {
            $status = "EXPIRING SOON"
        }

        $Log = New-Object System.Object
        $Log | Add-Member -MemberType NoteProperty -Name "ApplicationName" -Value $AppName
        $Log | Add-Member -MemberType NoteProperty -Name "ApplicationID" -Value $ApplID
        $Log | Add-Member -MemberType NoteProperty -Name "Secret Start Date" -Value $StartDate
        $Log | Add-Member -MemberType NoteProperty -Name "Secret End Date" -value $EndDate
        $Log | Add-Member -MemberType NoteProperty -Name "Certificate Start Date" -Value $Null
        $Log | Add-Member -MemberType NoteProperty -Name "Certificate End Date" -value $Null
        $Log | Add-Member -MemberType NoteProperty -Name 'KeyId' -Value $s.KeyId
        $Log | Add-Member -MemberType NoteProperty -Name 'Type' -Value $s.Type
        $Log | Add-Member -MemberType NoteProperty -Name "Status" -value $status

        $json = ConvertTo-Json $Log
        PostLogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

        $Logs += $Log
    }

    # Certs
    foreach ($c in $certs) {
        $StartDate = [Datetime]::Parse($c.startDateTime)
        $EndDate = [Datetime]::Parse($c.endDateTime)
        $status = "ACTIVE"

        if ($EndDate -le $today) {
            $status = "EXPIRED"
        }      
        elseif ($EndDate -le $futureDate) {
            $status = "EXPIRING SOON"
        }

        $Log = New-Object System.Object
        $Log | Add-Member -MemberType NoteProperty -Name "ApplicationName" -Value $AppName
        $Log | Add-Member -MemberType NoteProperty -Name "ApplicationID" -Value $ApplID
        $Log | Add-Member -MemberType NoteProperty -Name "Secret Start Date" -Value $Null
        $Log | Add-Member -MemberType NoteProperty -Name "Secret End Date" -value $Null
        $Log | Add-Member -MemberType NoteProperty -Name "Certificate Start Date" -Value $StartDate
        $Log | Add-Member -MemberType NoteProperty -Name "Certificate End Date" -value $EndDate
        $Log | Add-Member -MemberType NoteProperty -Name 'KeyId' -Value $c.KeyId
        $Log | Add-Member -MemberType NoteProperty -Name 'Type' -Value $c.Type
        $Log | Add-Member -MemberType NoteProperty -Name "Status" -value $status

        $json = ConvertTo-Json $Log
        PostLogAnalyticsData -customerId $customerId -sharedKey $sharedKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $logType

        $Logs += $Log
    }
}

# $Logs
$actives = $Logs | Where-Object -FilterScript {$_.Status -eq "ACTIVE"}
$expired = $Logs | Where-Object -FilterScript {$_.Status -eq "EXPIRED"}
$expiringsoon = $Logs | Where-Object -FilterScript {$_.Status -eq "EXPIRING SOON"}

$actives.Count
$expired.Count
$expiringsoon.Count

###########################################################################################################################
# STEP-2 Send an email from to all support team members.
###########################################################################################################################
$Header = @"
<style>
TABLE {border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #6495ED;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
</style>
"@

# $Logs | ConvertTo-Html -Fragment -As Table
$emailBody = $Logs | Sort-Object -Property "Status" -Descending | ConvertTo-Html -Head $Header -As Table  | Out-String

# logic-app-spn-alerts-to-email
$logicApp = "XXXX URL"
$emailsToNotify ="emailtonotify@domain"
$bodyHtml = ConvertTo-Json  @{
    subject = "Alert: Summary of SPN Secret Keys and Certificates that are ACTIVE, EXPIRED, EXPIRING SOON." 
    email = $emailsToNotify
    emailBody = $emailBody
 }

 Invoke-RestMethod -Uri $logicApp -Method Post -Body $bodyHtml -ContentType 'application/json'

############################################################################################################################
# STEP-3 Purge the old data
###########################################################################################################################
$AppId = 'xxxxxxxxxx'
$AppSecret = 'xxxxxxxxxx'

$TenantName = "xxxxxxxxxx"
$Url = "https://login.microsoftonline.com/$TenantName/oauth2/token?api-version=2020-06-01"

# Add System.Web for urlencode
# Add-Type -AssemblyName System.Web

# Create body
$Body = @{
    client_id     = $AppId
    client_secret = $AppSecret
    resource = 'https://management.core.windows.net/'
    grant_type    = 'client_credentials'
}

# Splat the parameters for Invoke-Restmethod for cleaner code
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method      = 'POST'
    Body        = $Body
    Uri         = $Url
}

# Request the token!
$Request = Invoke-RestMethod @PostSplat

# Create header
$Header = @{
    Authorization = "$($Request.token_type) $($Request.access_token)"
    host          = 'management.azure.com'
}

$Header
# log analytics URL with /purge
$purge_url = "https://management.azure.com/subscriptions/xxxxxxxxxx/resourceGroups/xxxxxxxxxx/providers/Microsoft.OperationalInsights/workspaces/xxxxxxxxxx/purge?api-version=2020-08-01"

# Purge all logs whose TimeGenerated date is less than yesterday
$body = @"
{
   "table": "SPN_Logs_CL",
   "filters": [
     {
       "column": "TimeGenerated",
       "operator": "<",
       "value": "$(((Get-Date).AddDays(-1)).ToString("yyyy-MM-dd"))"
     }
   ]
}
"@

$purgeID = Invoke-RestMethod -Uri $purge_url -Method POST -Headers $Header -Body $body
Write-Host $purgeID.operationId -ForegroundColor Green

$purge_status_url = "https://management.azure.com/subscriptions/xxxxxxxxxx/resourceGroups/xxxxxxxxxx/providers/Microsoft.OperationalInsights/workspaces/xxxxxxxxxx/operations/$($purgeID.operationId)?api-version=2020-08-01"
Invoke-RestMethod -Uri $purge_status_url -Method GET -Headers $Header

##########################################################################
# END
##########################################################################
