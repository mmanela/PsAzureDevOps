function traceMessage($message) {
    if($PsAzureDevOps.EnableLogging) {
        Write-Host $message
    }
}