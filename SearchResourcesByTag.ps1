Connect-AzAccount
$subs = Get-AzSubscription  
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    $VMs = Get-AzResource | Where-Object { $_.ResourceType -eq 'Microsoft.Compute/virtualMachines' } | Where-Object { $_.Tags -ne $null } | Where-Object { $_.Tags['Dept'] -eq "Billing" }
    foreach ($vm in $VMs) {

        echo $vm.Name
    }

}
