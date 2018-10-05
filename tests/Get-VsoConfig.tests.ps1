if(Get-Module PsAzureDevOps){ Remove-Module PsAzureDevOps }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path


"$here\..\functions\*.ps1", "$here\..\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }

Describe "Get-PsAzureDevOpsConfig" {

    BeforeAll {
        $globalConfig = '{"project": "globalProject", "account":"globalAccount"}'
        $localConfig = '{"project": "localProject", "repository":"localRepository"}'

        $globalConfigFolder = "TestDrive:\global\config"
        $script:globalConfigPath = Join-Path $globalConfigFolder $script:configFileName
        New-Item $globalConfigFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        New-Item $globalConfigPath -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
        Set-Content -Path $globalConfigPath -Value $globalConfig -Force
    
        $localConfigFolder = "TestDrive:\local\config"
        $localConfigPath = Join-Path $localConfigFolder $script:configFileName
        New-Item $localConfigFolder -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        New-Item $localConfigPath -ItemType File -ErrorAction SilentlyContinue | Out-Null
        Set-Content -Path $localConfigPath -Value $localConfig -Force
        Push-Location $localConfigFolder
    }
    
    AfterAll {
        Pop-Location
    }
    
    Context "When asking for just local config" {
        $result = Get-PsAzureDevOpsConfig -Local
                
        It "returns all local values"{
            $result.count | Should be 2
        }


        It "returns the local value"{
            $result.project | Should be "localProject"
        }
    }

    Context "When asking for just global config" {
        $result = Get-PsAzureDevOpsConfig -Global

        It "returns all local values"{
            $result.count | Should be 2
        }


        It "returns the global value"{
            $result.project | Should be "globalProject"
        }
    }

    Context "When asking for config" {
        $result = Get-PsAzureDevOpsConfig


        It "returns all combined values"{
            $result.count | Should be 3
        }

        It "returns the local value over global"{
            $result.project | Should be "localProject"
        }


        It "returns the global value when no local"{
            $result.account | Should be "globalAccount"
        }
    }

}