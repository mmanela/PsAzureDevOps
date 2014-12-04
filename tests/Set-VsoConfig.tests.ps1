$here = Split-Path -Parent $MyInvocation.MyCommand.Path

"$here\..\functions\*.ps1", "$here\..\cmdlets\*.ps1" |
Resolve-Path |
Where-Object { -not ($_.ProviderPath.Contains(".Tests.")) } |
ForEach-Object { . $_.ProviderPath }


Describe "Set-VsoConfig" {
   
    $script:globalConfigPath = Join-Path "TestDrive:\global\config" $script:configFileName
    New-Item  $globalConfigPath -ItemType File -Force -ErrorAction SilentlyContinue

    Context "When setting local config values" {

        $localConfigFolder = "TestDrive:\localConfig1"
        New-Item  $localConfigFolder -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder

        Set-VsoConfig Account GlobalAccount -Global

        Set-VsoConfig Project MyProject -Local
        Set-VsoConfig Account MyAccount -Local


        $localConfig = Get-VsoConfig -Local
        $globalConfig = Get-VsoConfig -Global
        $activeConfig = Get-VsoConfig

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
       
        Set-VsoConfig Project GlobalProject -Global
        Set-VsoConfig Account GlobalAccount -Global

        Set-VsoConfig Account MyAccount -Local

        $localConfig = Get-VsoConfig -Local
        $globalConfig = Get-VsoConfig -Global
        $activeConfig = Get-VsoConfig

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
       
        Set-VsoConfig Project MyProject -Local
        Set-VsoConfig Account MyAccount -Local

        $localConfigFolder2 = "TestDrive:\localConfig3\deep\nested"
        New-Item  $localConfigFolder2 -ItemType directory -ErrorAction SilentlyContinue
        Push-Location $localConfigFolder2


        Set-VsoConfig Account MyAccountNested -Local

        $localConfigNested = Get-VsoConfig -Local
        $activeConfigNested = Get-VsoConfig


        Pop-Location 


        $localConfig = Get-VsoConfig -Local
        $activeConfig = Get-VsoConfig

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