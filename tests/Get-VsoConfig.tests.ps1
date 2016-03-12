if(Get-Module PsVsts){ Remove-Module PsVsts }

$here = Split-Path -Parent $MyInvocation.MyCommand.Path


"$here\..\functions\*.ps1", "$here\..\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }

Describe "Get-VstsConfig" {

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
        $result = Get-VstsConfig -Local
                
        It "returns all local values"{
            $result.count | Should be 2
        }


        It "returns the local value"{
            $result.project | Should be "localProject"
        }
    }

    Context "When asking for just global config" {
        $result = Get-VstsConfig -Global

        It "returns all local values"{
            $result.count | Should be 2
        }


        It "returns the global value"{
            $result.project | Should be "globalProject"
        }
    }

    Context "When asking for config" {
        $result = Get-VstsConfig


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