$tools = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. (Join-Path $tools Setup.ps1)
try { 
    Install-PsVso "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
} catch {
    Write-ChocolateyFailure "PsVso" "$($_.Exception.Message)"
    throw 
}