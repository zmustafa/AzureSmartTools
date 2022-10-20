$searchForRbac = @("Contributor", "Owner")
$searchUserTypes = @("User","Unknown") ##$searchUserTypes = @("Group","User", "ServicePrincipal","Unknown")

$subNames = @("Subscription Name 1",
    "Subscription Name 2")

foreach ($subName in $subNames) {
    $azSub = Get-AzSubscription -SubscriptionName $subName
    Set-AzContext $azSub.id | Out-Null
    Write-Host "Scanning subscription : "  $subName
    Write-Host "------------------------------------------------------------------"
    $azlogs = @()
    $azlogs  += @($(("Scope`tDisplayName`tObjectId`tRBAC`tUserType")))
    $foundassigns = @()

    $Resources = Get-AzResource  
    foreach ($r in $Resources) {
       
        $ResourceId = $r.ResourceId
 
        $assign = Get-AzRoleAssignment -Scope $ResourceId -WarningAction Ignore | Where-Object { $_.RoleDefinitionName -in $searchForRbac } `
        | Where-Object { $_.ObjectType -in $searchUserTypes } 

        foreach ($a in $assign) {
            if ( $foundassigns -notcontains $($a.Scope + "`t" + $a.DisplayName + "`t" + $a.ObjectId + "`t" + $a.RoleDefinitionName + "`t" + $a.ObjectType)) {
                $v = @($(("" + $a.Scope + "`t" + $a.DisplayName + "`t" + $a.ObjectId + "`t" + $a.RoleDefinitionName + "`t" + $a.ObjectType )))
                $foundassigns += @($($a.Scope + "`t" + $a.DisplayName + "`t" + $a.ObjectId + "`t" + $a.RoleDefinitionName + "`t" + $a.ObjectType))
                $azlogs += $v
                Write-Host  $v
            }
        }
    }

    $azSubName = $azSub.Name
    $azlogs >> .\$azSubName.csv
    
}
