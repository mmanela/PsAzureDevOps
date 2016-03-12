PsVsts
=======
PsVsts provides a suite of PowerShell functions that help automate interaction with VisualStudio Online.

Install
----

Install chocolatey (if you don't have it yet)

```
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
```

Install PsVsts
```
choco install PsVsts
```

Once installed all the cmdlets should be auto-loaded and ready to use. If not just run
```
Import-Module PsVsts 
```


Usage
-----

PsVsts contains several cmdlets to automate some common operations. You can see details of each one through normal PowerShell docs. 


- **Get-MyWorkItems** 
      Gets the work items that are assigned to or created by you. Provides easy way to filter by open vs finished items.
      
- **Open-WorkItems**
      Opens work items in your web browser.
      
- **Push-ToVsts**      
      Takes a local git repo, creates a corresponding repo in your VSTS project, adds that repo as a remote origin and pushes your local repo to it.

- **Submit-PullRequest**
      Submits a pull request

- **Get-BuildStatus**
    Gets the status of the last build

- **Set-VstsConfig**
    Sets a config value for use in other PsVsts functions

- **Get-VstsConfig**
    Gets the config values
