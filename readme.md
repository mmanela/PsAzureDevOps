PsAzureDevOps
=======
PsAzureDevOps provides a suite of PowerShell functions that help automate interaction with VisualStudio Online.

Install
----

Install chocolatey (if you don't have it yet)

```
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
```

Install PsAzureDevOps

From PsGallery
```
Install-Module -Name PsAzureDevOps 
```

From Chocolatey

```
choco install PsAzureDevOps
```



Once installed all the cmdlets should be auto-loaded and ready to use. If not just run
```
Import-Module PsAzureDevOps 
```


Usage
-----

PsAzureDevOps contains several cmdlets to automate some common operations. You can see details of each one through normal PowerShell docs. 


- **Get-MyWorkItems** 
      Gets the work items that are assigned to or created by you. Provides easy way to filter by open vs finished items.
      
- **Get-WorkItems** 
      Gets the work items given a query.
      
- **Open-WorkItems**
      Opens work items in your web browser.
      
- **Push-ToAzureDevOps**      
      Takes a local git repo, creates a corresponding repo in your AzureDevOps project, adds that repo as a remote origin and pushes your local repo to it.

- **Submit-PullRequest**
      Submits a pull request

- **Get-Builds**
    Gets a list of builds

- **Get-BuildCodeCoverage**
    Gets the code coverage details for the specified build definition's latest successful build

- **Get-BuildArtifact**
    Gets the specified build artifact for the specified build definition's latest successful build

- **Set-PsAzureDevOpsConfig**
    Sets a config value for use in other PsAzureDevOps functions

- **Get-PsAzureDevOpsConfig**
    Gets the config values
