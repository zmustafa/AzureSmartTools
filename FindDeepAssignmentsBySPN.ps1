Select-AzSubscription -SubscriptionName "<SUBSCRIPTION_NAME>"
$spn=@("<SPN1>","<SPN2...>")

$Resources = Get-AzResource 
foreach ($Resource in $Resources) 
{
    $ass = Get-AzRoleAssignment -Scope $Resource.Id | Where-Object {$_.DisplayName -in $spn}
    foreach ($ax in $ass) 
    {
        Write-Host $ax.DisplayName "`t" $ax.Scope "`t" $ax.RoleDefinitionName
    }
     
}