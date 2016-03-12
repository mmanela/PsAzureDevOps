$tools = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. (Join-Path $tools Setup.ps1)
try { 
    Install-PsVsts "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
} catch {
    Write-ChocolateyFailure "PsVsts" "$($_.Exception.Message)"
    throw 
}