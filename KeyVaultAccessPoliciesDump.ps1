#Get list of eligible subscription
function GetEligibleSubscriptionList() {
    return Get-AzSubscription
}
function GetAKVAccessPolicies([object] $Subscription) {
    $context = Set-AzContext -Subscription $Subscription.Name
    $AllKVs = Get-AzKeyVault
    foreach ($KV in $AllKVs ) {
        $APs = (Get-AzKeyVault -VaultName $KV.VaultName).AccessPolicies | Select-Object *
        $KVVaultName = $KV.VaultName
        $p = "AccessPolicies-" + $KVVaultName + ".csv"
        $APs | Select-Object @{n='KeyVaultName';e={$KV.VaultName}}, * | Export-Csv -Path $p -NoTypeInformation
 
    }
}
#Get eligible subscription list
$SubsWithPermission = GetEligibleSubscriptionList
# Iterate over all subscriptions and all AKV
foreach ($sub in $SubsWithPermission) {
    GetAKVAccessPolicies -Subscription $sub
}
