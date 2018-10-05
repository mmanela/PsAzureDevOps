$moduleRoot = Split-Path -Path $MyInvocation.MyCommand.Path

Remove-Module PsAzureDevOps -ErrorAction SilentlyContinue

Import-Module $moduleRoot -DisableNameChecking -Force 
