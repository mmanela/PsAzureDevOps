$here = Split-Path -Parent $MyInvocation.MyCommand.Path

if(!$Global:PsVsts) { 
    $Global:PsVsts = @{} 
    $PsVsts.EnableLogging=$true
}

"$here\..\functions\*.ps1", "$here\..\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }


Describe "Set-VstsConfig" {
   
    $script:globalConfigPath = Join-Path "TestDrive:\global\config" $script:configFileName
    New-Item  $globalConfigPath -ItemType File -Force -ErrorAction SilentlyContinue

    Context "When setting config values" {
        $localConfigFolder = "TestDrive:\localConfig0"
        New-Item  $localConfigFolder -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder

        Set-VstsConfig Project MyProject
        Set-VstsConfig Account MyAccount


        $localConfig = Get-VstsConfig -Local

        It "sets values to local config file by default"{

            $localConfig.Count | Should be 2
            $localConfig.Project | Should be "MyProject"
            $localConfig.Account | Should be "MyAccount"
        }


        Pop-Location
    }

    Context "When setting local config values" {

        $localConfigFolder = "TestDrive:\localConfig1"
        New-Item  $localConfigFolder -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder

        Set-VstsConfig Account GlobalAccount -Global

        Set-VstsConfig Project MyProject -Local
        Set-VstsConfig Account MyAccount -Local


        $localConfig = Get-VstsConfig -Local
        $globalConfig = Get-VstsConfig -Global
        $activeConfig = Get-VstsConfig

        It "sets values to local config file"{

            $localConfig.Count | Should be 2
            $localConfig.Project | Should be "MyProject"
            $localConfig.Account | Should be "MyAccount"
        }

        It "they will show as the active values"{

            $activeConfig.Count | Should be 2
            $activeConfig.Project | Should be "MyProject"
            $activeConfig.Account | Should be "MyAccount"
        }


        It "does not set on the global config"{
            $globalConfig.Project | Should not be "MyProject"
            $globalConfig.Account | Should not be "MyAccount"

        } 

        Pop-Location
    }

    Context "When setting global config values" {

        $localConfigFolder = "TestDrive:\localConfig2"
        New-Item  $localConfigFolder -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder
       
        Set-VstsConfig Project GlobalProject -Global
        Set-VstsConfig Account GlobalAccount -Global

        Set-VstsConfig Account MyAccount -Local

        $localConfig = Get-VstsConfig -Local
        $globalConfig = Get-VstsConfig -Global
        $activeConfig = Get-VstsConfig

        It "sets values to global config file"{

            $globalConfig.Count | Should be 2
            $globalConfig.Project | Should be "GlobalProject"
            $globalConfig.Account | Should be "GlobalAccount"
        }

        It "they will show as the active values unless overriden in local file"{

            $activeConfig.Count | Should be 2
            $activeConfig.Project | Should be "GlobalProject"
            $activeConfig.Account | Should be "MyAccount"
        }



        It "does not set on the local config"{
            $localConfig.Count | Should be 1
            $localConfig.Account | Should be "MyAccount"
        }


        Pop-Location 
    }


    Context "When setting local config from nested folders" {

        $localConfigFolder = "TestDrive:\localConfig3"
        New-Item  $localConfigFolder -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder
       
        Set-VstsConfig Project MyProject -Local
        Set-VstsConfig Account MyAccount -Local

        $localConfigFolder2 = "TestDrive:\localConfig3\deep\nested"
        New-Item  $localConfigFolder2 -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder2


        Set-VstsConfig Account MyAccountNested -Local

        $localConfigNested = Get-VstsConfig -Local
        $activeConfigNested = Get-VstsConfig


        Pop-Location 


        $localConfig = Get-VstsConfig -Local
        $activeConfig = Get-VstsConfig

        It "sets values to local config file"{

            $localConfigNested.Count | Should be 2
            $localConfigNested.Project | Should be "MyProject"
            $localConfigNested.Account | Should be "MyAccountNested"
        }

        It "they will show as the active values"{

            $activeConfigNested.Count | Should be 2
            $activeConfigNested.Project | Should be "MyProject"
            $activeConfigNested.Account | Should be "MyAccountNested"
        }


        It "does not create a new local file if found in parent directory"{

            $localConfig.Count | Should be 2
            $localConfig.Project | Should be "MyProject"
            $localConfig.Account | Should be "MyAccountNested"
        }


        Pop-Location 
    }

}