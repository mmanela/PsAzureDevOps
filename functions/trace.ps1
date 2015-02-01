function traceMessage($message) {
    if($PsVso.EnableLogging) {
        Write-Host $message
    }
}