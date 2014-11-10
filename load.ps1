$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

Remove-Module PsVso -ErrorAction SilentlyContinue
Import-Module $moduleRoot -DisableNameChecking -Force -ErrorAction SilentlyContinue
