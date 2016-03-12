$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

Remove-Module PsVsts -ErrorAction SilentlyContinue

Import-Module $moduleRoot -DisableNameChecking -Force 
