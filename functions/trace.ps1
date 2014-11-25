function traceMessage($message) {
    if(-not $PsVso.SuppressLogging) {
        Write-Host $message
    }
}