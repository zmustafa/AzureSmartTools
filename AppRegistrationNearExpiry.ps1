$expiresInDays = 30
$exportPathCerts = "c:\Users\xxxx\Desktop\expiredCerts.csv"
$exportPathSecrets = "c:\Users\xxxx\Desktop\expiredSecrets.csv"
$today = (Get-Date).ToUniversalTime()
$futureDate = $today.AddDays($ExpiresInDays)

$expired  =  Get-AzureADApplication  -All:$true  |  ForEach-Object {
$app  =  $_
@(
Get-AzureADApplicationKeyCredential  -ObjectId  $_.ObjectId

$CustomKeyIdentifier  = (Get-AzureADApplicationKeyCredential  -ObjectId  $_.ObjectID).CustomKeyIdentifier
)| Where-Object {$_.EndDate -le $futureDate}|  ForEach-Object {
    $id  =  "Not set"
    if($CustomKeyIdentifier) {
        $id  =  [System.Convert]::ToBase64String($CustomKeyIdentifier)
    }
    $owner = Get-AzureADApplicationOwner -ObjectId $app.ObjectID
    
        [PSCustomObject] @{
        App =  $app.DisplayName
        ObjectID =  $app.ObjectId
        Owner = ($owner | Select-Object -ExpandProperty UserPrincipalName) -join ','
        AppId =  $app.AppId
        Type =  $_.GetType().name
        KeyIdentifier =  $id
        EndDate =  $_.EndDate
        }
    }
}

$expired  | export-csv -Path $exportPathCerts -NoTypeInformation

$expired  = Get-AzureADApplication  -All:$true  |  ForEach-Object {
$app  =  $_
@(
Get-AzureADApplicationPasswordCredential  -ObjectId  $_.ObjectId

$CustomKeyIdentifier  = (Get-AzureADApplicationPasswordCredential  -ObjectId  $_.ObjectID)
)| Where-Object {$_.EndDate -le $futureDate}|  ForEach-Object {
    $id  =  "Not set"
   
    $owner = Get-AzureADApplicationOwner -ObjectId $app.ObjectID
    
        [PSCustomObject] @{
        App =  $app.DisplayName
        ObjectID =  $app.ObjectId
        Owner = ($owner | Select-Object -ExpandProperty UserPrincipalName) -join ','
        AppId =  $app.AppId
        Type =  $_.GetType().name
        KeyIdentifier=  $_.KeyId
        ExpiryDate =  $_.EndDate
        }
    }
}

$expired  | export-csv -Path $exportPathSecrets -NoTypeInformation 
