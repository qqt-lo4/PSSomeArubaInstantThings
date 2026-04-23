function Get-AurbaInstantShowSummary {
    <#
    .SYNOPSIS
        Retrieves and parses the Aruba Instant system summary

    .DESCRIPTION
        Executes the "show summary" command via the API and parses the comprehensive
        output into structured data. Returns a hashtable containing clients, networks,
        access points, restricted subnets, RADIUS servers, RTLS servers, AP classes,
        and system properties.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, Get-ArubaInstantShowCmdResult
        will use $Global:ArubaInstantAPI.

    .OUTPUTS
        [hashtable]. Contains Lines, Properties, Clients, Networks, "Access Points",
        "Restricted Management Access Subnets", "RADIUS Servers", "RTLS Servers", and "AP Class".

    .EXAMPLE
        Get-AurbaInstantShowSummary

    .EXAMPLE
        $summary = Get-AurbaInstantShowSummary -ArubaInstantAPI $conn
        $summary.Clients
        $summary."Access Points"

    .NOTES
        Author: Loïc Ade
        Version: 1.1.0
        Dependencies: Select-LineRange, Convert-StringArrayToHashtable,
                      Convert-TSVWithDashLine (PSSomeDataThings)

        CHANGELOG:

        Version 1.1.0 - 2026-04-12 - Loïc Ade
            - Removed local global variable resolution (delegated to
              Get-ArubaInstantShowCmdResult)

        Version 1.0.0 - 2026-02-10 - Loïc Ade
            - Initial release
            - Parses "show summary" into structured data
            - Extracts clients, networks, access points, RADIUS/RTLS servers,
              restricted subnets, AP classes, and system properties
    #>
    Param(
        [object]$ArubaInstantAPI
    )
    Begin {
        $sCMD = "show summary"
    }
    Process {
        $aLines = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $ArubaInstantAPI -cmd $sCMD -ReturnResult
        $aClientLines = Select-LineRange -InputArray $aLines -StartRegex "^[0-9]+ Clients?$" -IncludeStartLine $true -EndRegex "^[0-9]+ Networks?$" -IncludeEndLine $false | Select-Object -Skip 2
        $aClient = Convert-TSVWithDashLine -dataArray $aClientLines -ToPSObject
        $aNetworkLines = Select-LineRange -InputArray $aLines -StartRegex "^[0-9]+ Networks?$" -IncludeStartLine $true -EndRegex "^[0-9]+ Access Points?$" -IncludeEndLine $false | Select-Object -Skip 2
        $aNetworks = Convert-TSVWithDashLine -dataArray $aNetworkLines -ToPSObject
        $aAccessPointsLines = Select-LineRange -InputArray $aLines -StartRegex "^[0-9]+ Access Points?$" -IncludeStartLine $true -EndRegex "^Restricted Management Access Subnets$" -IncludeEndLine $false | Select-Object -Skip 2
        $aAccessPoints = Convert-TSVWithDashLine -dataArray $aAccessPointsLines -ToPSObject
        $aRestrictedManagementAccessSubnetsLines = Select-LineRange -InputArray $aLines -StartRegex "^Restricted Management Access Subnets$" -IncludeStartLine $true -EndRegex "^RADIUS Servers$" -IncludeEndLine $false | Select-Object -Skip 2
        $aRestrictedManagementAccessSubnets = Convert-TSVWithDashLine -dataArray $aRestrictedManagementAccessSubnetsLines -ToPSObject
        $aRadiusServersLines = Select-LineRange -InputArray $aLines -StartRegex "^RADIUS Servers$" -IncludeStartLine $true -EndRegex "^RTLS Servers$" -IncludeEndLine $false | Select-Object -Skip 2
        $aRadiusServers = Convert-TSVWithDashLine -dataArray $aRadiusServersLines -ToPSObject
        $aRTLSServersLines = Select-LineRange -InputArray $aLines -StartRegex "^RTLS Servers$" -IncludeStartLine $true -EndRegex "^[0-9]+ AP Class(es)?$" -IncludeEndLine $false | Select-Object -Skip 2
        $aRTLSServers = Convert-TSVWithDashLine -dataArray $aRTLSServersLines -ToPSObject
        $aAPClassLines = Select-LineRange -InputArray $aLines -StartRegex "^[0-9]+ AP Class(es)?$" -IncludeStartLine $true -EndRegex '^\s*(.+?)\s*:\s*(.*)$' -IncludeEndLine $false | Select-Object -Skip 2
        $aAPClass = Convert-TSVWithDashLine -dataArray $aAPClassLines -ToPSObject
        $aFirstLines = Select-LineRange -InputArray $aLines -EndRegex "^[0-9]+ Clients?$" -IncludeEndLine $false -IncludeStartLine $false
        $aEndLines = Select-LineRange -InputArray $aLines -StartRegex "^[0-9]+ AP Class(es)?$" | Select-Object -Skip ($aAPClass.Count + 5)
        $hProperties = $aFirstLines + $aEndLines | Convert-StringArrayToHashtable
        $hResult = @{
            Lines = $aLines
            Properties = $hProperties
            Clients = $aClient
            Networks = $aNetworks
            "Access Points" = $aAccessPoints
            "Restricted Management Access Subnets" = $aRestrictedManagementAccessSubnets
            "RADIUS Servers" = $aRadiusServers
            "RTLS Servers" = $aRTLSServers
            "AP Class" = $aAPClass
        }
        return $hResult
    }
}