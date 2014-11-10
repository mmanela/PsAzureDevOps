function Install-PsVso($here) {
    $PsVsoPath=Join-Path $env:AppData PsVso
    if(!(test-Path $PsVsoPath)){
        mkdir $PsVsoPath
    }
     
    foreach($folder in (Get-ChildItem $here | ?{ $_.PSIsContainer })){
        $target=Join-Path $PsVsoPath $folder.BaseName
        if(test-Path $target){
            Remove-Item $target -Recurse -Force
        }
    }
    
    Copy-Item "$here\*" $PsVsoPath -Recurse -Force -Exclude ChocolateyInstall.ps1, Setup.*

    PersistPsVsoPathToEnvironmentVariable "PSModulePath"
   
    $successMsg = @"
The PsVso Module has been copied to $PsVsoPath and added to your Module path. 
You will need to open a new console for the path to be visible.
To import the module and see its command do the following:
PS:>Import-Module PsVso
PS:>Get-Command -Module PsVso.*

To find more info visit https://github.com/mmanela/PsVso or use:
PS:>Import-Module PsVso
PS:>Get-Help PsVso
"@
    Write-Host $successMsg

}


function PersistPsVsoPathToEnvironmentVariable($variableName){
    $value = [Environment]::GetEnvironmentVariable($variableName, 'User')
    if($value){
        $values=($value -split ';' | ?{ !($_.ToLower() -match "\\PsVso$")}) -join ';'
        $values+=";$PsVsoPath"
    } 
    elseif($variableName -eq "PSModulePath") {
        $values=[environment]::getfolderpath("mydocuments")
        $values +="\WindowsPowerShell\Modules;$PsVsoPath"
    }
    else {
        $values ="$PsVsoPath"
    }
    if(!$value -or !($values -contains $PsVsoPath)){
        $values = $values.Replace(';;',';')
        [Environment]::SetEnvironmentVariable($variableName, $values, 'User')
        $varValue = Get-Content env:\$variableName
        $varValue += ";$PsVsoPath"
        $varValue = $varValue.Replace(';;',';')
        Set-Content env:\$variableName -value $varValue
    }
}