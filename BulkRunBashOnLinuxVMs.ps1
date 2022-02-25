Connect-AzAccount
$subs = Get-AzSubscription 
foreach ($sub in $subs) {
    Select-AzSubscription -SubscriptionId $sub.Id
    echo '#!/bin/bash' >>.\msgtst.sh
    echo 'echo test: $1 $2 $3 $4 $5 $6' >>.\msgtst.sh
    $Script_paramz = [ordered]@{"par1" = "val1"; "par2" = "val2"; "par3" = "val3"; "par4" = "val4"; "par5" = "val5"; "par6" = "val6" }
    $VMs = Get-AzResource | Where-Object { $_.ResourceType -eq 'Microsoft.Compute/virtualMachines' } | Where-Object { $_.Tags -ne $null } | Where-Object { $_.Tags['Dept'] -eq "Billing" }
    foreach ($vm in $VMs) {
        Invoke-AzVMRunCommand -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -ScriptPath ".\msgtst.sh" -CommandId RunShellScript -Parameter $Script_paramz -Verbose
    }
} 
