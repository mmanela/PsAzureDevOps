PsVso
=======
PsVso provides a suite of PowerShell functions that help automate interaction with VisualStudio Online.

Install
----

Install chocolatey (if you don't have it yet)

```
iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
```

Install PsVso
```
choco install PsVso
```

Once installed all the cmdlets should be auto-loaded and ready to use.

Usage
-----

PsVso contains several cmdlets to automate some common operations. You can see details of each one through normal PowerShell docs. 

| Cmdlet        | Description   |
| ------------- |---------------|
| Push-ToVso      | Takes a local git repo, creates a corresponding repo in your VSO project, adds that repo as a remote origin and pushes your local repo to it. |
| Submit-PullRequest      | Submits a pull request      |
| Get-BuildStatus | Gets the status of the last build      |
| Set-VsoConfig | Sets a config value for use in other PsVso functions |
| Get-VsoConfig | Gets the config values |