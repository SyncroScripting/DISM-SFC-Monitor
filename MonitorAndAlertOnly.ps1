Import-Module $env:SyncroModule

#IntegrityMonitor.ps1

#DISM Space
$dismspacecheck = DISM /online /Cleanup-Image /AnalyzeComponentStore
if($dismspacecheck -like "*Component Store Cleanup Recommended : Yes*")
{
    $dismmatch = [string]$dismspacecheck -match "Reclaimable Packages : (\d*)"
    if($dismmatch){
        if($Matches.2 -gt 4){
            Rmm-Alert -Category 'DISM Cleanup' -Body 'DISM Cleanup Required.'
        }
    }
}

#DISM Health
$dismhealth = DISM /Online /Cleanup-Image /ScanHealth
if($dismhealth -like "*The component store is repairable.*"){
Rmm-Alert -Category 'DISM Health' -Body 'Windows Image Corrupt.'
}


# SFC
$sfcverify = ($(sfc /verifyonly) -split '' | ? {$_ -and [byte][char]$_ -ne 0}) -join ''
if($sfcverify -like "*found integrity violations*"){
    Write-Output("SFC found corrupt files.")
    Rmm-Alert -Category 'SFC' -Body 'SFC fixes required.'
}
