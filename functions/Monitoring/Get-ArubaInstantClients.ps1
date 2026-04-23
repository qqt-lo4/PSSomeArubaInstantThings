function Get-ArubaInstantClient {
    <#
    .SYNOPSIS
        Retrieves the list of connected clients from an Aruba Instant access point

    .DESCRIPTION
        Executes the "show clients" command via the API and parses the output
        into a structured format. Returns client connection information including
        MAC addresses, IP addresses, usernames, and connection details.

    .PARAMETER ArubaInstantAPI
        The API connection object. If not specified, uses $Global:ArubaMobilityControllerAPI.

    .PARAMETER iap_ip_addr
        The IP address of the target IAP. Defaults to the controller IP if not specified.

    .OUTPUTS
        [array]. Array of hashtables, each representing a connected client.

    .EXAMPLE
        Get-ArubaInstantClient

    .EXAMPLE
        Get-ArubaInstantClient -ArubaInstantAPI $conn -iap_ip_addr "192.168.1.10"

    .NOTES
        Author: Loïc Ade
        Version: 1.1.0
        Dependencies: Convert-TSVWithDashLine (PSSomeDataThings)

        CHANGELOG:

        Version 1.1.0 - 2026-04-12 - Loïc Ade
            - Refactored to use Get-ArubaInstantShowCmdResult -ReturnResult
              instead of direct API call and manual parsing

        Version 1.0.0 - 2026-02-10 - Loïc Ade
            - Initial release
            - Retrieves and parses connected clients from "show clients" command
    #>
    Param(
        [object]$ArubaInstantAPI,
        [string]$iap_ip_addr
    )
    Begin {
        $sCMD = "show clients"
    }
    Process {
        $oResult = Get-ArubaInstantShowCmdResult -ArubaInstantAPI $ArubaInstantAPI -iap_ip_addr $iap_ip_addr -cmd $sCMD -ReturnResult
        $oResult = $oResult[2..($oResult.Count - 3)]
        return Convert-TSVWithDashLine $oResult
    }
}