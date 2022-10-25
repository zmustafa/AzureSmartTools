
$subNames=Get-AzSubscription 
$azlogs = @()
    $azlogs  += @($(("Scope`tAllowAll")))
    $azlogs >> .\AllowAllWindowsAzureIps.csv
	$azlogs = @()
foreach ($subName in $subNames) {
    $azSub = Get-AzSubscription -SubscriptionId $subName.Id
    Set-AzContext $azSub.id | Out-Null
    Write-Host "Scanning subscription : "  $subName
    Write-Host "------------------------------------------------------------------"
    $foundassigns = @()

    $Resources = Get-AzResource  | Where-Object {$_.ResourceType -eq 'Microsoft.Sql/servers'} 

    foreach ($r in $Resources) {
       
	   $found= Get-AzSqlServerFirewallRule -ServerName $r.Name -ResourceGroupName $r.ResourceGroupName | Where-Object {$_.FirewallRuleName -eq 'AllowAllWindowsAzureIps'}
	   
	   foreach($f in $found){
		      if ( $foundassigns -notcontains $($r.Id + "`t" + $f.FirewallRuleName)) {
                $v = @($(("" + $r.Id + "`t" + $f.FirewallRuleName)))
                $foundassigns += @($($r.Id + "`t" + $f.FirewallRuleName))
                $azlogs += $v
                Write-Host  $v
            }
	   }		        
    }

$azSubName = $azSub.Name
$azlogs >> .\AllowAllWindowsAzureIps.csv
$azlogs = @()
}
