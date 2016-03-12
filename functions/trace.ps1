function traceMessage($message) {
    if($PsVsts.EnableLogging) {
        Write-Host $message
    }
}