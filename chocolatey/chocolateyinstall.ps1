$tools = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. (Join-Path $tools Setup.ps1)
try { 
    Install-PsAzureDevOps "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
} catch {
    Write-ChocolateyFailure "PsAzureDevOps" "$($_.Exception.Message)"
    throw 
}