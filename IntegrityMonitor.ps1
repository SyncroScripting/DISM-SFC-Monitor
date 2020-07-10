Import-Module $env:SyncroModule

#IntegrityMonitor.ps1

#DISM Space
$dismspacecheck = DISM /online /Cleanup-Image /AnalyzeComponentStore
if($dismspacecheck -like "*Component Store Cleanup Recommended : Yes*")
{
    $dismmatch = [string]$dismspacecheck -match "Reclaimable Packages : (\d*)"
    if($dismmatch){
        if($Matches.2 -gt 4){
            Write-Output("Cleanup needed. Doing it. ")
            DISM /online /Cleanup-Image /StartComponentCleanup
            Log-Activity -Message "DISM Cleanup Performed" -EventName "DISM Cleanup"
        } else {
            Write-Output("Cleanup recommended but not needed.")
        }
    }
} else {
    Write-Output("Cleanup not needed.")
}

#DISM Health
$dismhealth = DISM /Online /Cleanup-Image /ScanHealth
if($dismhealth -like "*The component store is repairable.*"){
$dismhealthfix = DISM /Online /Cleanup-Image /RestoreHealth
if($dismhealthfix -like "*The restore operation completed successfully.*"){
    Log-Activity -Message "DISM Fixes Successful." -EventName "DISM Health"
    Write-Output("DISM Fixes Performed.")
}

} elseif ($dismhealth -like "*No component store corruption detected.*") {
    Write-Output("DISM Health is good.")
}


# SFC
$sfcverify = ($(sfc /verifyonly) -split '' | ? {$_ -and [byte][char]$_ -ne 0}) -join ''
if($sfcverify -like "*found integrity violations*"){
    Write-Output("SFC found corrupt files. Fixing.")
    $sfcfix = ($(sfc /scannow) -split '' | ? {$_ -and [byte][char]$_ -ne 0}) -join ''
    if($sfcfix -like "*unable to fix*"){
        Rmm-Alert -Category 'SFC' -Body 'SFC fixes failed!'
        Write-Output("SFC was unable to fix the issues.")
    } else {
        Write-Output("SFC repair successful.")
        Log-Activity -Message "SFC Fixes Successful!" -EventName "SFC"
    }
} else {
    Write-Output("SFC is all good.")
}
