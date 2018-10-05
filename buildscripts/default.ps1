$psake.use_exit_on_error = $true
properties {
    $baseDir = (Split-Path -parent $psake.build_script_dir)

    $packageDir = "$baseDir\_package"


    if(Get-Command Git -ErrorAction SilentlyContinue) {
        $versionTag = git describe --abbrev=0 --tags
        $version = $versionTag + ".0"
    }
    else {
        $version="1.0.0"
        $changeset = "0"
    }

    if($versionOverride) {
        $version = $versionOverride
    }

    $nugetExe = "$env:ChocolateyInstall\bin\nuget.exe"
}


Task default -depends Build
Task Build -depends Test, Package
Task Package -depends Clean-PackageFiles, Version-Module, Pack-Nuget
Task Push-Public -depends Push-Chocolatey


Task Test {
    Import-Module pester
    
    pushd "$baseDir"
        
    if($testName){
        Invoke-Pester -Script $baseDir/tests -TestName $testName
    }
    else{
        Invoke-Pester -Script $baseDir/tests
    }
    popd
}

Task Version-Module {
    (Get-Content "$baseDir\PsAzureDevOps.psd1") `
      | % {$_ -replace "^ModuleVersion = '.*'`$", "ModuleVersion = '$version'" } `
      | Set-Content "$baseDir\PsAzureDevOps.psd1"
}


Task Pack-Nuget {

    create $packageDir
    
    exec {
      . $nugetExe pack "$baseDir\PsAzureDevOps.nuspec" -OutputDirectory $packageDir `
      -NoPackageAnalysis -version $version
    }
}

Task Push-Chocolatey {
    exec { chocolatey push $packageDir\PsAzureDevOps.$version.nupkg }
}

Task Clean-PackageFiles {
    clean $packageDir
}


function create([string[]]$paths) {
  foreach ($path in $paths) {
    if(-not (Test-Path $path)) {
      new-item -path $path -type directory | out-null
    }
  }
}

function clean([string[]]$paths) {
    foreach ($path in $paths) {
        remove-item -force -recurse $path -ErrorAction SilentlyContinue
    }
}


function roboexec([scriptblock]$cmd) {
    & $cmd | out-null
    if ($lastexitcode -eq 0) { throw "No files were copied for command: " + $cmd }
}
