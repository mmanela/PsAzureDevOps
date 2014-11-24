$packageDir = (Resolve-Path _package).Path

& $env:ChocolateyInstall\chocolateyinstall\chocolatey.ps1 install PsVso -source "$packageDir;http://chocolatey.org/api/v2" -force