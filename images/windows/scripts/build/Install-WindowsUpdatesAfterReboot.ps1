################################################################################
##  File: Install-WindowsUpdatesAfterReboot.ps1
##  Desc: Waits for Windows Updates to finish installing after reboot
##  Note: Increased retry count to handle large cumulative updates (e.g., 25GB KB5068787)
################################################################################

Invoke-ScriptBlockWithRetry -RetryCount 20 -RetryIntervalSeconds 120 -Command {
    $inProgress = Get-WindowsUpdateStates | Where-Object State -eq "Running" | Where-Object Title -notmatch "Microsoft Defender Antivirus"
    if ( $inProgress ) {
        $title = $inProgress.Title -join "`n"
        throw "Windows updates are still installing: $title"
    }
}
