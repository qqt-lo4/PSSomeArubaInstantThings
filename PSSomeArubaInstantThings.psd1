@{
    # Module manifest for PSSomeArubaInstantThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeArubaInstantThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'e3f7a291-6c84-4b50-9d13-a82e5f4c6b07'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Aruba Instant API wrapper: access point connection, client monitoring, show commands, AP image version and statistics.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('Aruba', 'ArubaInstant', 'WiFi', 'AccessPoint', 'Monitoring', 'API')
            ProjectUri = ''
        }
    }
}
