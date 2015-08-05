@{

# Script module or binary module file associated with this manifest.
RootModule = 'PsVso.psm1'

# Version number of this module.
ModuleVersion = '0.5.0'

# ID used to uniquely identify this module
GUID = '30f59c9a-b2b9-4300-b53a-d3f9e78c0cc0'

# Author of this module
Author = 'Matthew Manela'

# Company or vendor of this module
CompanyName = 'Matthew Manela'

# Copyright statement for this module
Copyright = 'Copyright (c) 2014 by Matthew Manela, licensed under Apache 2.0 License.'

# Description of the functionality provided by this module
Description = 'PsVso provides a suite of PowerShell functions that help automate interaction with VisualStudio Online.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Minimum version of the .NET Framework required by this module
DotNetFrameworkVersion = '4.5'

# Functions to export from this module
FunctionsToExport = '*'

RequiredAssemblies = @( 
    "lib\VsoOM\Microsoft.VisualStudio.Services.Client.dll",
    "lib\VsoOM\Microsoft.VisualStudio.Services.WebApi.dll",
    "lib\VsoOM\Microsoft.VisualStudio.Services.Common.dll",
    "System.Net.Http.dll",
    "lib\VsoRestProxy\VsoRestProxy.dll"
)


# # Cmdlets to export from this module
 CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# # Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

PrivateData = @{
    # PSData is module packaging and gallery metadata embedded in PrivateData
    # It's for rebuilding PowerShellGet (and PoshCode) NuGet-style packages
    # We had to do this because it's the only place we're allowed to extend the manifest
    # https://connect.microsoft.com/PowerShell/feedback/details/421837
    PSData = @{
        # The primary categorization of this module (from the TechNet Gallery tech tree).
        Category = "Scripting Techniques"

        # Keyword tags to help users find this module via navigations and search.
        Tags = @('powershell','VSO','git','VisualStudio','VisualStudioOnline')

        # The web address of an icon which can be used in galleries to represent this module
        #IconUri = "http://iconpath"

        # The web address of this module's project or support homepage.
        ProjectUri = "https://github.com/mmanela/PsVso"

        # The web address of this module's license. Points to a page that's embeddable and linkable.
        LicenseUri = "http://www.apache.org/licenses/LICENSE-2.0.html"

        # Release notes for this particular version of the module
        # ReleaseNotes = False

        # If true, the LicenseUrl points to an end-user license (not just a source license) which requires the user agreement before use.
        # RequireLicenseAcceptance = ""

        # Indicates this is a pre-release/  ing version of the module.
        IsPrerelease = 'False'
    }
}

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}
