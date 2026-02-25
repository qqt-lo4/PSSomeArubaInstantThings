function Get-AurbaInstantAPImageVersion {
    <#
    .SYNOPSIS
        Retrieves the primary partition firmware version of an Aruba Instant AP

    .DESCRIPTION
        Executes the "show image version" command via the API and parses the
        output to extract the primary partition build version string.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, uses $Global:ArubaMobilityControllerAPI.

    .OUTPUTS
        [string]. The primary partition build version.

    .EXAMPLE
        Get-AurbaInstantAPImageVersion

    .EXAMPLE
        Get-AurbaInstantAPImageVersion -ArubaInstantAPI $conn

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ArubaInstantAPI
    )
    Begin {
        $oArubaInstantAPI = if ($ArubaInstantAPI) { $ArubaInstantAPI } else { $Global:ArubaMobilityControllerAPI }
    }
    Process {
        $oResult = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $oArubaInstantAPI -cmd "show image version"
        $ss = $oResult.'Command output'.Split("`n") | ForEach-Object { Select-String -InputObject $_ -Pattern "Primary Partition Build Version +:(?<version>[^ ]+).+" }
        return ($ss.Matches.Groups | Where-Object { $_.name -eq "version" }).Value
    }
}