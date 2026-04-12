function Get-AurbaInstantAPImageVersion {
    <#
    .SYNOPSIS
        Retrieves the primary partition firmware version of an Aruba Instant AP

    .DESCRIPTION
        Executes the "show image version" command via the API and parses the
        output to extract the primary partition build version string.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, Get-ArubaInstantShowCmdResult
        will use $Global:ArubaInstantAPI.

    .OUTPUTS
        [string]. The primary partition build version.

    .EXAMPLE
        Get-AurbaInstantAPImageVersion

    .EXAMPLE
        Get-AurbaInstantAPImageVersion -ArubaInstantAPI $conn

    .NOTES
        Author: Loïc Ade
        Version: 1.1.0

        CHANGELOG:

        Version 1.1.0 - 2026-04-12 - Loïc Ade
            - Removed local global variable resolution (delegated to
              Get-ArubaInstantShowCmdResult)

        Version 1.0.0 - 2026-02-10 - Loïc Ade
            - Initial release
            - Parses "show image version" output for primary partition build version
    #>
    Param(
        [object]$ArubaInstantAPI
    )
    Begin {
        $sCMD = "show image version"
    }
    Process {
        $oResult = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $ArubaInstantAPI -cmd $sCMD
        $ss = $oResult.'Command output'.Split("`n") | ForEach-Object { Select-String -InputObject $_ -Pattern "Primary Partition Build Version +:(?<version>[^ ]+).+" }
        return ($ss.Matches.Groups | Where-Object { $_.name -eq "version" }).Value
    }
}